# Monkey patch redis session store
class RedisSessionStore
  def set_session(env, sid, session_data, options = nil) # rubocop: disable MethodLength, LineLength
    $redis.lock("sid_#{sid}", life: 10, acquire: 1) do |lock|
      expiry = (options || env.fetch(ENV_SESSION_OPTIONS_KEY))[:expire_after]
      if expiry
        redis.setex(prefixed(sid), expiry, encode(session_data))
      else
        redis.set(prefixed(sid), encode(session_data))
      end
      return sid
    end
  rescue Errno::ECONNREFUSED => e
    on_redis_down.call(e, env, sid) if on_redis_down
    return false
  end
end

class Portal < Ohm::Model
  include Rails.application.routes.url_helpers
  extend ActiveModel::Naming
  extend ActiveModel::Translation
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Serialization
  include ActiveModel::AttributeMethods
  include ActiveModel::AttributeAssignment

  include OhmCustom::DataTypes
  include Ohm::Timestamps

  attr_accessor :lang, :api_client, :background_params, :current_url
  cattr_accessor :encrypted_attributes
  
  thread_local_accessor :current_session
  # thread_local_accessor :api_client

  def initialize(attributes = {})
    @background_params ||= {}
    super

    I18n.locale = lang if lang #set the locale if provided
    
    if self.persisted?
      attributes.each do |att, val|
        next unless respond_to?(att)
        val = Portal.decrypt(val) if self.class.encrypted_attributes && self.class.encrypted_attributes[self.class.to_s] && self.class.encrypted_attributes[self.class.to_s].include?(att.to_sym)
        send(:"#{att}=", val)
      end
    end
  end

  def self.encrypted(*attr)
    self.encrypted_attributes ||= {}
    self.encrypted_attributes[self.to_s] ||= []
    self.encrypted_attributes[self.to_s] = attr
  end

  def persisted?
    to_key ? true : false
  end

  def update_attribute(key, value)
    send("#{key}=", value)
    save
  end

  def save
    attrs = self.attributes.clone
    self.attributes.each do |k,v|
      next unless self.class.encrypted_attributes && self.class.encrypted_attributes[self.class.to_s] && self.class.encrypted_attributes[self.class.to_s].include?(k)
      send(:"#{k}=", Portal.encrypt(v))
    end
    super
    attrs.each do |k,v|
      next unless self.class.encrypted_attributes && self.class.encrypted_attributes[self.class.to_s] && self.class.encrypted_attributes[self.class.to_s].include?(k)
      send(:"#{k}=", v)
    end
    self
  end

  def update_attributes(atts)
    atts.each do |att, val|
      next unless respond_to?(att)
      val = Portal.decrypt(val) if self.class.encrypted_attributes && self.class.encrypted_attributes[self.class.to_s] && self.class.encrypted_attributes[self.class.to_s].include?(att.to_sym)
      send(:"#{att}=", val)
    end
  end


  def self.encrypt(data)
    crypt = ActiveSupport::MessageEncryptor.new(ENV['encrypt_key'])
    crypt.encrypt_and_sign(data)
  end

  def self.decrypt(data)
    crypt = ActiveSupport::MessageEncryptor.new(ENV['encrypt_key'])
    crypt.decrypt_and_verify(data) 
  end


  # Have to override this method to support ohm and RESTful froms
  def to_key
    begin
      [id]
    rescue
      nil
    end
  end

  def self.validates_uniqueness_of(*args)
    validates_with(UniquenessValidator, _merge_attributes(args))
  end

  def self.get_session(sid)
    session_data = Ohm.redis.call('GET', "#{Rails.configuration.session_options[:redis][:key_prefix]}#{sid}")
    begin
      Marshal.load(session_data).symbolize_keys if session_data 
    rescue => e
      Rails.logger.error "GET_SESSION ERROR: #{session_data.inspect}"
    end
  end

  def self.set_session(sid, data)
    $redis.lock("sid_#{sid}", life: 10, acquire: 1) do |lock|
      Ohm.redis.call('SET', "#{Rails.configuration.session_options[:redis][:key_prefix]}#{sid}", Marshal.dump(data))
    end
  end


  def self.delete_session(sid)
    Ohm.redis.call('DEL', "#{Rails.configuration.session_options[:redis][:key_prefix]}#{sid}")
  end

  def self.email_capture(email, type, guid = nil, opt_in = 0, nhl_opt_in = 0)
    OPTIN_REDIS.set "optin:#{email}", "#{opt_in},#{nhl_opt_in}"

    return false unless Rails.env.production?

    begin
      conn = Faraday.new(:url => 'http://sked.sportsnet.ca') do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
      res = conn.get "/gcl_email.php?email=#{email}&type=#{type}"
      true
    rescue Faraday::Error::ConnectionFailed => e
      false
    end
  end

  def self.update_locales
    # Pull latest when dyno restarts in production
    if defined?(Rails)
      `mkdir -p #{Rails.root}/config/locales/#{ENV['APP_NAME']}`
      Localeapp::CLI::Pull.new(
        api_key: ENV['LOCALEAPP_API_KEY'],
        translation_data_directory: "#{Rails.root}/config/locales/#{ENV['APP_NAME']}"
      ).execute

      # Pull common localization
      Localeapp::CLI::Pull.new(
        api_key: ENV['COMMON_LOCALEAPP_API_KEY'],
        translation_data_directory: "#{Rails.root}/config/locales"
      ).execute
    end

    I18n.backend.load_translations Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s, Rails.root.join('config', 'locales', ENV['APP_NAME'], '*.{rb,yml}').to_s]
  end

  ZUORA_CA_STATES = {
    'en' => {
      'Alberta'                   => 'AB',
      'British Columbia'          => 'BC',
      'Manitoba'                  => 'MB',
      'New Brunswick'             => 'NB',
      'Newfoundland and Labrador' => 'NL',
      'Nova Scotia'               => 'NS',
      'Ontario'                   => 'ON',
      'Prince Edward Island'      => 'PE',
      'Quebec'                    => 'QC',
      'Saskatchewan'              => 'SK',
      'Northwest Territories'     => 'NT',
      'Yukon'                     => 'YT',
      'Nunavut'                   => 'NU'
    },
    'fr' => {
      'Alberta'                     => 'AB',
      'Colombie-Britannique'        => 'BC',
      'Manitoba'                    => 'MB',
      'Nouveau-Brunswick'           => 'NB',
      'Terre-Neuve-et-Labrador'     => 'NL',
      'Nouvelle-Écosse'             => 'NS',
      'Ontario'                     => 'ON',
      'l\'île du Prince-Édouard'    => 'PE',
      'Québec'                      => 'QC',
      'Saskatchewan'                => 'SK',
      '(territoires du) Nord-Ouest' => 'NT',
      '(territoire du) Yukon'       => 'YT',
      'Nunavut'                     => 'NU'
    }
  }

  RDS_REGIONS = {
    'en' => {
      'Alberta'                      => 'AB',
      'British Columbia'             => 'BC',
      'Manitoba'                     => 'MB',
      'Ontario - West of Belleville' => 'ON',
      'Saskatchewan'                 => 'SK',
      'Northwest Territories'        => 'NT',
      'Yukon'                        => 'YT',
      'Nunavut'                      => 'NU'
    },
    'fr' => {
      'Alberta'                       => 'AB',
      'Colombie-Britannique'          => 'BC',
      'Manitoba'                      => 'MB',
      'Ontario - Ouest de Belleville' => 'ON',
      'Saskatchewan'                  => 'SK',
      '(territoires du) Nord-Ouest'   => 'NT',
      '(territoire du) Yukon'         => 'YT',
      'Nunavut'                       => 'NU'
    }
  }

  ZUORA_US_STATES = {
    'en' => {
      "Alaska"                                           => "AK",
      "Alabama"                                          => "AL",
      "Arkansas"                                         => "AR",
      "American Samoa"                                   => "AS",
      "Arizona"                                          => "AZ",
      "California"                                       => "CA",
      "Colorado"                                         => "CO",
      "Connecticut"                                      => "CT",
      "District of Columbia"                             => "DC",
      "Delaware"                                         => "DE",
      "Florida"                                          => "FL",
      "Georgia"                                          => "GA",
      "Guam"                                             => "GU",
      "Hawaii"                                           => "HI",
      "Iowa"                                             => "IA",
      "Idaho"                                            => "ID",
      "Illinois"                                         => "IL",
      "Indiana"                                          => "IN",
      "Kansas"                                           => "KS",
      "Kentucky"                                         => "KY",
      "Louisiana"                                        => "LA",
      "Massachusetts"                                    => "MA",
      "Maryland"                                         => "MD",
      "Maine"                                            => "ME",
      "Michigan"                                         => "MI",
      "Minnesota"                                        => "MN",
      "Missouri"                                         => "MO",
      "Northern Mariana Islands"                         => "MP",
      "Mississippi"                                      => "MS",
      "Montana"                                          => "MT",
      "North Carolina"                                   => "NC",
      "North Dakota"                                     => "ND",
      "Nebraska"                                         => "NE",
      "New Hampshire"                                    => "NH",
      "New Jersey"                                       => "NJ",
      "New Mexico"                                       => "NM",
      "Nevada"                                           => "NV",
      "New York"                                         => "NY",
      "Ohio"                                             => "OH",
      "Oklahoma"                                         => "OK",
      "Oregon"                                           => "OR",
      "Pennsylvania"                                     => "PA",
      "Puerto Rico"                                      => "PR",
      "Rhode Island"                                     => "RI",
      "South Carolina"                                   => "SC",
      "South Dakota"                                     => "SD",
      "Tennessee"                                        => "TN",
      "Texas"                                            => "TX",
      "United States Minor Outlying Islands"             => "UM",
      "Utah"                                             => "UT",
      "Virginia"                                         => "VA",
      "Virgin Islands"                                   => "VI",
      "Vermont"                                          => "VT",
      "Washington"                                       => "WA",
      "Wisconsin"                                        => "WI",
      "West Virginia"                                    => "WV",
      "Wyoming"                                          => "WY",
      "Armed Forces Americas (except Canada)"            => "AA",
      "Armed Forces Africa, Canada, Europe, Middle East" => "AE",
      "Armed Forces Pacific"                             => "AP"
    },
    'fr' => {
      "Alaska"                                           => "AK",
      "Alabama"                                          => "AL",
      "Arkansas"                                         => "AR",
      "American Samoa"                                   => "AS",
      "Arizona"                                          => "AZ",
      "Californie​"                                      => "CA",
      "Caroline du Nord"                                 => "NC",
      "Caroline du Sud"                                  => "SC",
      "Colorado"                                         => "CO",
      "Connecticut"                                      => "CT",
      "Dakota du Nord"                                   => "ND",
      "Dakota du Sud"                                    => "SD",
      "District de Columbia"                             => "DC",
      "Delaware"                                         => "DE",
      "Floride"                                          => "FL",
      "Géorgie"                                          => "GA",
      "Guam"                                             => "GU",
      "Hawaï"                                            => "HI",
      "Iowa"                                             => "IA",
      "Idaho"                                            => "ID",
      "Illinois"                                         => "IL",
      "Indiana"                                          => "IN",
      "Kansas"                                           => "KS",
      "Kentucky"                                         => "KY",
      "Louisiane"                                        => "LA",
      "Massachusetts"                                    => "MA",
      "Maryland"                                         => "MD",
      "Maine"                                            => "ME",
      "Michigan"                                         => "MI",
      "Minnesota"                                        => "MN",
      "Missouri"                                         => "MO",
      "Îles Mariannes du Nord"                           => "MP",
      "Mississippi"                                      => "MS",
      "Montana"                                          => "MT",
      "Nebraska"                                         => "NE",
      "New Hampshire"                                    => "NH",
      "New Jersey"                                       => "NJ",
      "Nouveau-Mexique"                                  => "NM",
      "Nevada"                                           => "NV",
      "New York"                                         => "NY",
      "Ohio"                                             => "OH",
      "Oklahoma"                                         => "OK",
      "Oregon"                                           => "OR",
      "Pennsylvanie"                                     => "PA",
      "Puerto Rico"                                      => "PR",
      "Rhode Island"                                     => "RI",
      "Tennessee"                                        => "TN",
      "Texas"                                            => "TX",
      "United States Minor Outlying Islands"             => "UM",
      "Utah"                                             => "UT",
      "Virginie"                                         => "VA",
      "Virginie-Occidentale"                             => "WV",
      "Virgin Islands"                                   => "VI",
      "Vermont"                                          => "VT",
      "Washington"                                       => "WA",
      "Wisconsin"                                        => "WI",
      "Wyoming"                                          => "WY",
      "Armed Forces Americas (except Canada)"            => "AA",
      "Armed Forces Africa, Canada, Europe, Middle East" => "AE",
      "Armed Forces Pacific"                             => "AP"
    }
  }
 


  ZUORA_COUNTRIES = {
    'en' => {
      'Afghanistan'                                  => 'AFG',
      'Aland Islands'                                => 'ALA',
      'Albania'                                      => 'ALB',
      'Algeria'                                      => 'DZA',
      'American Samoa'                               => 'ASM',
      'Andorra'                                      => 'AND',
      'Angola'                                       => 'AGO',
      'Anguilla'                                     => 'AIA',
      'Antarctica'                                   => 'ATA',
      'Antigua And Barbuda'                          => 'ATG',
      'Argentina'                                    => 'ARG',
      'Armenia'                                      => 'ARM',
      'Aruba'                                        => 'ABW',
      'Australia'                                    => 'AUS',
      'Austria'                                      => 'AUT',
      'Azerbaijan'                                   => 'AZE',
      'Bahamas'                                      => 'BHS',
      'Bahrain'                                      => 'BHR',
      'Bangladesh'                                   => 'BGD',
      'Barbados'                                     => 'BRB',
      'Belarus'                                      => 'BLR',
      'Belgium'                                      => 'BEL',
      'Belize'                                       => 'BLZ',
      'Benin'                                        => 'BEN',
      'Bermuda'                                      => 'BMU',
      'Bhutan'                                       => 'BTN',
      'Bolivia'                                      => 'BOL',
      'Bonaire, Saint Eustatius and Saba'            => 'BES',
      'Bosnia and Herzegovina'                       => 'BIH',
      'Botswana'                                     => 'BWA',
      'Bouvet Island'                                => 'BVT',
      'Brazil'                                       => 'BRA',
      'British Indian Ocean Territory'               => 'IOT',
      'Brunei Darussalam'                            => 'BRN',
      'Bulgaria'                                     => 'BGR',
      'Burkina Faso'                                 => 'BFA',
      'Burundi'                                      => 'BDI',
      'Cambodia'                                     => 'KHM',
      'Cameroon'                                     => 'CMR',
      'Canada'                                       => 'CAN',
      'Cape Verde'                                   => 'CPV',
      'Cayman Islands'                               => 'CYM',
      'Central African Republic'                     => 'CAF',
      'Chad'                                         => 'TCD',
      'Chile'                                        => 'CHL',
      'China'                                        => 'CHN',
      'Christmas Island'                             => 'CXR',
      'Cocos (Keeling) Islands'                      => 'CCK',
      'Colombia'                                     => 'COL',
      'Comoros'                                      => 'COM',
      'Congo'                                        => 'COG',
      'Congo, the Democratic Republic of the'        => 'COD',
      'Cook Islands'                                 => 'COK',
      'Costa Rica'                                   => 'CRI',
      'Cote d\'Ivoire'                               => 'CIV',
      'Croatia'                                      => 'HRV',
      'Cuba'                                         => 'CUB',
      'Curacao'                                      => 'CUW',
      'Cyprus'                                       => 'CYP',
      'Czech Republic'                               => 'CZE',
      'Denmark'                                      => 'DNK',
      'Djibouti'                                     => 'DJI',
      'Dominica'                                     => 'DMA',
      'Dominican Republic'                           => 'DOM',
      'Ecuador'                                      => 'ECU',
      'Egypt'                                        => 'EGY',
      'El Salvador'                                  => 'SLV',
      'Equatorial Guinea'                            => 'GNQ',
      'Eritrea'                                      => 'ERI',
      'Estonia'                                      => 'EST',
      'Ethiopia'                                     => 'ETH',
      'Falkland Islands (Malvinas)'                  => 'FLK',
      'Faroe Islands'                                => 'FRO',
      'Fiji'                                         => 'FJI',
      'Finland'                                      => 'FIN',
      'France'                                       => 'FRA',
      'French Guiana'                                => 'GUF',
      'French Polynesia'                             => 'PYF',
      'French Southern Territories'                  => 'ATF',
      'Gabon'                                        => 'GAB',
      'Gambia'                                       => 'GMB',
      'Georgia'                                      => 'GEO',
      'Germany'                                      => 'DEU',
      'Ghana'                                        => 'GHA',
      'Gibraltar'                                    => 'GIB',
      'Greece'                                       => 'GRC',
      'Greenland'                                    => 'GRL',
      'Grenada'                                      => 'GRD',
      'Guadeloupe'                                   => 'GLP',
      'Guam'                                         => 'GUM',
      'Guatemala'                                    => 'GTM',
      'Guernsey'                                     => 'GGY',
      'Guinea'                                       => 'GIN',
      'Guinea-Bissau'                                => 'GNB',
      'Guyana'                                       => 'GUY',
      'Haiti'                                        => 'HTI',
      'Heard Island and McDonald Islands'            => 'HMD',
      'Holy See (Vatican City State)'                => 'VAT',
      'Honduras'                                     => 'HND',
      'Hong Kong'                                    => 'HKG',
      'Hungary'                                      => 'HUN',
      'Iceland'                                      => 'ISL',
      'India'                                        => 'IND',
      'Indonesia'                                    => 'IDN',
      'Iran, Islamic Republic of'                    => 'IRN',
      'Iraq'                                         => 'IRQ',
      'Ireland'                                      => 'IRL',
      'Isle of Man'                                  => 'IMN',
      'Israel'                                       => 'ISR',
      'Italy'                                        => 'ITA',
      'Jamaica'                                      => 'JAM',
      'Japan'                                        => 'JPN',
      'Jersey'                                       => 'JEY',
      'Jordan'                                       => 'JOR',
      'Kazakhstan'                                   => 'KAZ',
      'Kenya'                                        => 'KEN',
      'Kiribati'                                     => 'KIR',
      'Korea, Democratic People\'s Republic of'      => 'PRK',
      'Korea, Republic of'                           => 'KOR',
      'Kuwait'                                       => 'KWT',
      'Kyrgyzstan'                                   => 'KGZ',
      'Lao People\'s Democratic Republic'            => 'LAO',
      'Latvia'                                       => 'LVA',
      'Lebanon'                                      => 'LBN',
      'Lesotho'                                      => 'LSO',
      'Liberia'                                      => 'LBR',
      'Libyan Arab Jamahiriya'                       => 'LBY',
      'Liechtenstein'                                => 'LIE',
      'Lithuania'                                    => 'LTU',
      'Luxembourg'                                   => 'LUX',
      'Macao'                                        => 'MAC',
      'Macedonia, the former Yugoslav Republic of'   => 'MKD',
      'Madagascar'                                   => 'MDG',
      'Malawi'                                       => 'MWI',
      'Malaysia'                                     => 'MYS',
      'Maldives'                                     => 'MDV',
      'Mali'                                         => 'MLI',
      'Malta'                                        => 'MLT',
      'Marshall Islands'                             => 'MHL',
      'Martinique'                                   => 'MTQ',
      'Mauritania'                                   => 'MRT',
      'Mauritius'                                    => 'MUS',
      'Mayotte'                                      => 'MYT',
      'Mexico'                                       => 'MEX',
      'Micronesia, Federated States of'              => 'FSM',
      'Moldova, Republic of'                         => 'MDA',
      'Monaco'                                       => 'MCO',
      'Mongolia'                                     => 'MNG',
      'Montenegro'                                   => 'MNE',
      'Montserrat'                                   => 'MSR',
      'Morocco'                                      => 'MAR',
      'Mozambique'                                   => 'MOZ',
      'Myanmar'                                      => 'MMR',
      'Namibia'                                      => 'NAM',
      'Nauru'                                        => 'NRU',
      'Nepal'                                        => 'NPL',
      'Netherlands'                                  => 'NLD',
      'Netherlands Antilles'                         => 'ANT',
      'New Caledonia'                                => 'NCL',
      'New Zealand'                                  => 'NZL',
      'Nicaragua'                                    => 'NIC',
      'Niger'                                        => 'NER',
      'Nigeria'                                      => 'NGA',
      'Niue'                                         => 'NIU',
      'Norfolk Island'                               => 'NFK',
      'Northern Mariana Islands'                     => 'MNP',
      'Norway'                                       => 'NOR',
      'Oman'                                         => 'OMN',
      'Pakistan'                                     => 'PAK',
      'Palau'                                        => 'PLW',
      'Palestinian Territory, Occupied'              => 'PSE',
      'Panama'                                       => 'PAN',
      'Papua New Guinea'                             => 'PNG',
      'Paraguay'                                     => 'PRY',
      'Peru'                                         => 'PER',
      'Philippines'                                  => 'PHL',
      'Pitcairn'                                     => 'PCN',
      'Poland'                                       => 'POL',
      'Portugal'                                     => 'PRT',
      'Puerto Rico'                                  => 'PRI',
      'Qatar'                                        => 'QAT',
      'Reunion'                                      => 'REU',
      'Romania'                                      => 'ROU',
      'Russian Federation'                           => 'RUS',
      'Rwanda'                                       => 'RWA',
      'Saint Barthelemy'                             => 'BLM',
      'Saint Helena'                                 => 'SHN',
      'Saint Kitts and Nevis'                        => 'KNA',
      'Saint Lucia'                                  => 'LCA',
      'Saint Martin (French part)'                   => 'MAF',
      'Saint Pierre and Miquelon'                    => 'SPM',
      'Saint Vincent and the Grenadines'             => 'VCT',
      'Samoa'                                        => 'WSM',
      'San Marino'                                   => 'SMR',
      'Sao Tome and Principe'                        => 'STP',
      'Saudi Arabia'                                 => 'SAU',
      'Senegal'                                      => 'SEN',
      'Serbia'                                       => 'SRB',
      'Seychelles'                                   => 'SYC',
      'Sierra Leone'                                 => 'SLE',
      'Singapore'                                    => 'SGP',
      'Sint Maarten'                                 => 'SXM',
      'Slovakia'                                     => 'SVK',
      'Slovenia'                                     => 'SVN',
      'Solomon Islands'                              => 'SLB',
      'Somalia'                                      => 'SOM',
      'South Africa'                                 => 'ZAF',
      'South Georgia and the South Sandwich Islands' => 'SGS',
      'Spain'                                        => 'ESP',
      'Sri Lanka'                                    => 'LKA',
      'Sudan'                                        => 'SDN',
      'Suriname'                                     => 'SUR',
      'Svalbard and Jan Mayen'                       => 'SJM',
      'Swaziland'                                    => 'SWZ',
      'Sweden'                                       => 'SWE',
      'Switzerland'                                  => 'CHE',
      'Syrian Arab Republic'                         => 'SYR',
      'Taiwan'                                       => 'TWN',
      'Tajikistan'                                   => 'TJK',
      'Tanzania, United Republic of'                 => 'TZA',
      'Thailand'                                     => 'THA',
      'Timor-Leste'                                  => 'TLS',
      'Togo'                                         => 'TGO',
      'Tokelau'                                      => 'TKL',
      'Tonga'                                        => 'TON',
      'Trinidad and Tobago'                          => 'TTO',
      'Tunisia'                                      => 'TUN',
      'Turkey'                                       => 'TUR',
      'Turkmenistan'                                 => 'TKM',
      'Turks and Caicos Islands'                     => 'TCA',
      'Tuvalu'                                       => 'TUV',
      'Uganda'                                       => 'UGA',
      'Ukraine'                                      => 'UKR',
      'United Arab Emirates'                         => 'ARE',
      'United Kingdom'                               => 'GBR',
      'United States'                                => 'USA',
      'United States Minor Outlying Islands'         => 'UMI',
      'Uruguay'                                      => 'URY',
      'Uzbekistan'                                   => 'UZB',
      'Vanuatu'                                      => 'VUT',
      'Venezuela'                                    => 'VEN',
      'Viet Nam'                                     => 'VNM',
      'Virgin Islands, British'                      => 'VGB',
      'Virgin Islands, U.S.'                         => 'VIR',
      'Wallis and Futuna'                            => 'WLF',
      'Western Sahara'                               => 'ESH',
      'Yemen'                                        => 'YEM',
      'Zambia'                                       => 'ZMB',
      'Zimbabwe'                                     => 'ZWE',
    },
    'fr' => {
      'Afghanistan'                                 => 'AFG',
      'Afrique du Sud'                              => 'ZAF',
      'Åland'                                       => 'ALA',
      'Albanie'                                     => 'ALB',
      'Algérie'                                     => 'DZA',
      'Allemagne'                                   => 'DEU',
      'American Samoa'                              => 'ASM',
      'Andorre'                                     => 'AND',
      'Angola'                                      => 'AGO',
      'Anguilla'                                    => 'AIA',
      'Antarctique'                                 => 'ATA',
      'Antigua-et-Barbuda'                          => 'ATG',
      'Arabie saoudite'                             => 'SAU',
      'Argentine'                                   => 'ARG',
      'Arménie'                                     => 'ARM',
      'Aruba'                                       => 'ABW',
      'Australie'                                   => 'AUS',
      'Autriche'                                    => 'AUT',
      'Azerbaïdjan'                                 => 'AZE',
      'Bahamas'                                     => 'BHS',
      'Bahreïn'                                     => 'BHR',
      'Bangladesh'                                  => 'BGD',
      'Barbade'                                     => 'BRB',
      'Belgique'                                    => 'BEL',
      'Belize'                                      => 'BLZ',
      'Bermudes'                                    => 'BMU',
      'Bhoutan'                                     => 'BTN',
      'Biélorussie'                                 => 'BLR',
      'Bolivie'                                     => 'BOL',
      'Bosnie-Herzégovine'                          => 'BIH',
      'Botswana'                                    => 'BWA',
      'Bouvet Island'                               => 'BVT',
      'Brunéi Darussalam'                           => 'BRN',
      'Brésil'                                      => 'BRA',
      'Bulgarie'                                    => 'BGR',
      'Burkina Faso'                                => 'BFA',
      'Burundi'                                     => 'BDI',
      'Bénin'                                       => 'BEN',
      'Cambodge'                                    => 'KHM',
      'Cameroun'                                    => 'CMR',
      'Canada'                                      => 'CAN',
      'Cap-Vert'                                    => 'CPV',
      'Chili'                                       => 'CHL',
      'Chine'                                       => 'CHN',
      'Chypre'                                      => 'CYP',
      'Colombie'                                    => 'COL',
      'Comores'                                     => 'COM',
      'Congo'                                       => 'COG',
      'Corée du Nord'                               => 'PRK',
      'Corée du Sud'                                => 'KOR',
      'Costa Rica'                                  => 'CRI',
      'Croatie'                                     => 'HRV',
      'Cuba'                                        => 'CUB',
      'Curaçao'                                     => 'CUW',
      'Côte d\'Ivoire'                              => 'CIV',
      'Danemark'                                    => 'DNK',
      'Djibouti'                                    => 'DJI',
      'Dominique'                                   => 'DMA',
      'Égypte'                                      => 'EGY',
      'El Salvador'                                 => 'SLV',
      'Émirats arabes unis'                         => 'ARE',
      'Équateur'                                    => 'ECU',
      'Érythrée'                                    => 'ERI',
      'Espagne'                                     => 'ESP',
      'Estonie'                                     => 'EST',
      'États-Unis'                                  => 'USA',
      'Éthiopie'                                    => 'ETH',
      'Fidji'                                       => 'FJI',
      'Finlande'                                    => 'FIN',
      'France'                                      => 'FRA',
      'Gabon'                                       => 'GAB',
      'Gambie'                                      => 'GMB',
      'Ghana'                                       => 'GHA',
      'Gibraltar'                                   => 'GIB',
      'Grenade'                                     => 'GRD',
      'Groenland'                                   => 'GRL',
      'Grèce'                                       => 'GRC',
      'Guadeloupe'                                  => 'GLP',
      'Guam'                                        => 'GUM',
      'Guatemala'                                   => 'GTM',
      'Guernesey'                                   => 'GGY',
      'Guinée équatoriale'                          => 'GNQ',
      'Guinée'                                      => 'GIN',
      'Guinée-Bissau'                               => 'GNB',
      'Guyana'                                      => 'GUY',
      'Guyane française'                            => 'GUF',
      'Géorgie du Sud et les Îles Sandwich du Sud'  => 'SGS',
      'Géorgie'                                     => 'GEO',
      'Haïti'                                       => 'HTI',
      'Honduras'                                    => 'HND',
      'Hong Kong'                                   => 'HKG',
      'Hongrie'                                     => 'HUN',
      'Île Christmas'                               => 'CXR',
      'Île de Man'                                  => 'IMN',
      'Île Maurice'                                 => 'MUS',
      'Îles Caïmans'                                => 'CYM',
      'Îles Cocos (Keeling)'                        => 'CCK',
      'Îles Cook'                                   => 'COK',
      'Îles Falkland (Malvinas)'                    => 'FLK',
      'Îles Féroé'                                  => 'FRO',
      'Îles Heard et McDonald'                      => 'HMD',
      'Îles Mariannes du Nord'                      => 'MNP',
      'Îles Marshall'                               => 'MHL',
      'Îles Pitcairn'                               => 'PCN',
      'Îles Salomon'                                => 'SLB',
      'Îles Turks et Caïques'                       => 'TCA',
      'Îles Vierges britanniques'                   => 'VGB',
      'Îles Vierges des États-Unis'                 => 'VIR',
      'Inde'                                        => 'IND',
      'Indonésie'                                   => 'IDN',
      'Iran'                                        => 'IRN',
      'Iraq'                                        => 'IRQ',
      'Irlande'                                     => 'IRL',
      'Islande'                                     => 'ISL',
      'Israël'                                      => 'ISR',
      'Italie'                                      => 'ITA',
      'Jamaïque'                                    => 'JAM',
      'Japon'                                       => 'JPN',
      'Jersey'                                      => 'JEY',
      'Jordanie'                                    => 'JOR',
      'Kazakhstan'                                  => 'KAZ',
      'Kenya'                                       => 'KEN',
      'Kirghizistan'                                => 'KGZ',
      'Kiribati'                                    => 'KIR',
      'Koweït'                                      => 'KWT',
      'Laos'                                        => 'LAO',
      'Lesotho'                                     => 'LSO',
      'Lettonie'                                    => 'LVA',
      'Liban'                                       => 'LBN',
      'Libye'                                       => 'LBY',
      'Libéria'                                     => 'LBR',
      'Liechtenstein'                               => 'LIE',
      'Lituanie'                                    => 'LTU',
      'Luxembourg'                                  => 'LUX',
      'Macao'                                       => 'MAC',
      'Macédoine'                                   => 'MKD',
      'Madagascar'                                  => 'MDG',
      'Malaisie'                                    => 'MYS',
      'Malawi'                                      => 'MWI',
      'Maldives'                                    => 'MDV',
      'Mali'                                        => 'MLI',
      'Malte'                                       => 'MLT',
      'Maroc'                                       => 'MAR',
      'Martinique'                                  => 'MTQ',
      'Mauritanie'                                  => 'MRT',
      'Mayotte'                                     => 'MYT',
      'Mexique'                                     => 'MEX',
      'Micronésie'                                  => 'FSM',
      'Moldavie'                                    => 'MDA',
      'Monaco'                                      => 'MCO',
      'Mongolie'                                    => 'MNG',
      'Montserrat'                                  => 'MSR',
      'Monténégro'                                  => 'MNE',
      'Mozambique'                                  => 'MOZ',
      'Myanmar'                                     => 'MMR',
      'Namibie'                                     => 'NAM',
      'Nauru'                                       => 'NRU',
      'Netherlands Antilles'                        => 'ANT',
      'Nicaragua'                                   => 'NIC',
      'Niger'                                       => 'NER',
      'Nigeria'                                     => 'NGA',
      'Niué'                                        => 'NIU',
      'Norfolk Island'                              => 'NFK',
      'Norvège'                                     => 'NOR',
      'Nouvelle-Calédonie'                          => 'NCL',
      'Nouvelle-Zélande'                            => 'NZL',
      'Népal'                                       => 'NPL',
      'Oman'                                        => 'OMN',
      'Ouganda'                                     => 'UGA',
      'Ouzbékistan'                                 => 'UZB',
      'Pakistan'                                    => 'PAK',
      'Palaos'                                      => 'PLW',
      'Palestine'                                   => 'PSE',
      'Panama'                                      => 'PAN',
      'Papouasie-Nouvelle-Guinée'                   => 'PNG',
      'Paraguay'                                    => 'PRY',
      'Pays-bas caribéens'                          => 'BES',
      'Pays-Bas'                                    => 'NLD',
      'Philippines'                                 => 'PHL',
      'Pologne'                                     => 'POL',
      'Polynésie française'                         => 'PYF',
      'Porto Rico'                                  => 'PRI',
      'Portugal'                                    => 'PRT',
      'Pérou'                                       => 'PER',
      'Qatar'                                       => 'QAT',
      'Republique de Trinite et Tobago'             => 'TTO',
      'Roumanie'                                    => 'ROU',
      'Royaume-uni'                                 => 'GBR',
      'Russie'                                      => 'RUS',
      'Rwanda'                                      => 'RWA',
      'République centrafricaine'                   => 'CAF',
      'République domincaine'                       => 'DOM',
      'République démocratique du Congo'            => 'COD',
      'République Tchèque'                          => 'CZE',
      'Réunion'                                     => 'REU',
      'Sahara occidental'                           => 'ESH',
      'Saint-Barthélemy'                            => 'BLM',
      'Saint-Kitts-et-Nevis'                        => 'KNA',
      'Saint-Marin'                                 => 'SMR',
      'Saint-Martin'                                => 'MAF',
      'Saint-Martin'                                => 'SXM',
      'Saint-Pierre-et-Miquelon'                    => 'SPM',
      'Saint-Vincent et les Grenadines'             => 'VCT',
      'Sainte-Hélène'                               => 'SHN',
      'Sainte-Lucie'                                => 'LCA',
      'Samoa'                                       => 'WSM',
      'Sao Tomé-et-Principe'                        => 'STP',
      'Serbie'                                      => 'SRB',
      'Seychelles'                                  => 'SYC',
      'Sierra Leone'                                => 'SLE',
      'Singapour'                                   => 'SGP',
      'Slovaquie'                                   => 'SVK',
      'Slovénie'                                    => 'SVN',
      'Somalie'                                     => 'SOM',
      'Soudan'                                      => 'SDN',
      'Sri Lanka'                                   => 'LKA',
      'Suisse'                                      => 'CHE',
      'Suriname'                                    => 'SUR',
      'Suède'                                       => 'SWE',
      'Svalbard et Jan Mayen'                       => 'SJM',
      'Swaziland'                                   => 'SWZ',
      'Syrie'                                       => 'SYR',
      'Sénégal'                                     => 'SEN',
      'Tadjikistan'                                 => 'TJK',
      'Tanzanie'                                    => 'TZA',
      'Taïwan'                                      => 'TWN',
      'Tchad'                                       => 'TCD',
      'Terres australes et antarctiques françaises' => 'ATF',
      'Territoire britannique de l\'océan indien'   => 'IOT',
      'Thaïlande'                                   => 'THA',
      'Timor-Leste'                                 => 'TLS',
      'Togo'                                        => 'TGO',
      'Tokelau'                                     => 'TKL',
      'Tonga'                                       => 'TON',
      'Tunisie'                                     => 'TUN',
      'Turkménistan'                                => 'TKM',
      'Turquie'                                     => 'TUR',
      'Tuvalu'                                      => 'TUV',
      'Ukraine'                                     => 'UKR',
      'United States Minor Outlying Islands'        => 'UMI',
      'Uruguay'                                     => 'URY',
      'Vanuatu'                                     => 'VUT',
      'Vatican'                                     => 'VAT',
      'Venezuela'                                   => 'VEN',
      'Vietnam'                                     => 'VNM',
      'Wallis et Futuna'                            => 'WLF',
      'Yémen'                                       => 'YEM',
      'Zambie'                                      => 'ZMB',
      'Zimbabwe'                                    => 'ZWE',      
    }
  }
    
end
