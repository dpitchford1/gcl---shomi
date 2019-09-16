class Session < Portal
  attr_accessor :password, :smtoken, :smagentname, :smenc, :smauthreason, :messages

  attribute :username
  attribute :user_token
  attribute :guid
  attribute :user_id
  attribute :email_address
  attribute :lang_pref
  attribute :created, Type::Integer

  index :username
  index :user_token
  index :user_id
  index :guid
  index :email_address
  index :created

  reference :profile, :Profile
  reference :promo_code, :PromoCode

  validates_presence_of :username, :password

  def self.login(params)
    puts "START LOGIN"
    lang = params[:lang]
    api_client = params[:api_client]
    api_client.setup(params) # We have to set username/password to client
    I18n.locale = lang

    s = Session.new(params)
    profile = Profile.find(username: s.username).first || Profile.create(params)
    begin
      if params[:smsession]
        result = api_client.siteminder_login_with_smsession(params)
      else
        puts "START API LOGIN"
        result = api_client.login(params)
      end

      return temp_password(params.merge(result)) if result[:result_code] == 6

      s.assign_attributes(result)
      s.profile_id = profile.id
      s.created = Time.now
      s.save

      # Limit active session to 10
      sessions = Session.find(profile_id: s.profile_id).to_a
      sessions.sort! { |a,b| b.created <=> a.created }
      if sessions.count > 10
        sessions[10..sessions.count].each {|s| s.delete } 
      end

      profile.assign_attributes(s.attributes)

      entitlement_result = api_client.get_entitlement(ip_address: params[:ip_address])
      profile.entitlement = entitlement_result[:entitlement]
      profile.login_attempts = 0
      profile.last_login_attempt = Time.now
      #fetch user offers

      if ENV["user_offers"]
        offer = api_client.fetch_secure_offer
        s.background_params[:offer_id] = offer.offer_id if offer
      end
      profile.save
      profile.delete_accounts
      
      if entitlement_result[:accounts]
        entitlement_result[:accounts].each do |a|
          profile.accounts << Account.create(a) if a[:account_token]
        end
      end

      if [504, -1].include? entitlement_result[:result_code]
        s.background_params[:redirect]    = s.profiles_path
        s.background_params[:notice]      = entitlement_result[lang.to_sym]
        s.background_params[:notice_type] = :alert
        s.background_params[:entitlement_failed] = true
      else
        s.background_params[:redirect]    = params[:promo_code] ? s.promo_contact_path : s.profiles_path
        s.background_params[:redirect]    = s.new_order_path(order: { billing_option: 'cc'})  if params[:user_region] && !profile.eligible? # RDS hack
        s.background_params[:redirect]    = s.profiles_path(app: "true") if params[:app] == "true"
        s.background_params[:notice]      = I18n.t('sessions.logged_in')
        s.background_params[:notice_type] = :notice
      end

      Portal.email_capture(profile.email_address, profile.entitlement ? profile.entitlement[:level] : "unknown", api_client.guid, profile.email_opt_in.to_s.to_i, profile.nhl_opt_in.to_s.to_i)
      s.background_params[:signed_in] = 'success' 
    rescue GodzillaApi::Exception => e
      profile.login_attempts += 1
      profile.last_login_attempt = Time.now
      profile.save

      api_error = e.error
      s.errors[:base] << api_error[lang.to_sym]
      s.background_params[:signed_in] = 'failed' 
      s.background_params[:redirect]  = s.new_session_path
    end
    s
  end

  def self.temp_password(params)
    s = Session.new(params)
    s.background_params[:redirect]    = s.change_password_path
    s.background_params[:notice]      = I18n.t('sessions.change_password')
    s.background_params[:notice_type] = :notice
    s
  end

  def logged?
    persisted? && errors.blank?
  end

  def profile
    Profile.find(username: username).first
  end

  def hash
    Digest::SHA256.hexdigest username
  end
end
