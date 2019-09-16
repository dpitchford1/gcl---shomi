class ApiClient
  attr_accessor :client

  def initialize(params={})
    @client ||= GodzillaApi::Client.new(params)
  end

  def setup(params)
    params.symbolize_keys!
    @client.username      = params[:username]
    @client.password      = params[:password]
    @client.user_id       = params[:user_id]
    @client.guid          = params[:guid]
    @client.email_address = params[:email_address]
    @client.user_token    = params[:user_token]
  end  

  def method_missing(m, *args, &block)
    @client.send(m.to_s, *args)
  end

  def login(params)
    start_time = Time.now
    result = @client.siteminder_login(params)
    response_time = Time.now - start_time
    puts "login response time #{response_time} seconds for #{@client.username}"
    setup(result)
    result
  end

  def create_order(params)
    start_time = Time.now
    create_order = @client.order(params)
    response_time = Time.now - start_time
    puts "create_order response time #{response_time} seconds for #{@client.username}"
    return create_order
  end

  def get_profile
    start_time = Time.now
    profile = @client.profile
    response_time = Time.now - start_time
    puts "get_profile response time #{response_time} seconds for #{@client.username}"
    return profile
  end

  def account_lookup(params)
    start_time = Time.now
    account_lookup_response = @client.account(params)
    response_time = Time.now - start_time
    puts "account_lookup response time #{response_time} seconds for #{@client.username}"
    return account_lookup_response
  end

  def fetch_offers(params={})
    params.symbolize_keys!
    start_time = Time.now
    offers = @client.offers(product: params[:product], province: params[:province], postal_code: params[:postal_code])
    response_time = Time.now - start_time
    puts "fetch_offers response time #{response_time} seconds for #{@client.username}"
    if offers && offers[:offers]
      Offer.find(product_code: params[:product].downcase).each { |o| o.delete }
      offers[:offers].each do |o|
        Offer.create(o.merge({product_code: params[:product].downcase}))
      end
    end
    Offer.all    
  end

  def fetch_secure_offer(params={})
    start_time = Time.now
    begin
      offers = @client.offers(secure: true, product: params['product'], province: params['province'], postal_code: params['postal_code'])
    rescue GodzillaApi::Exception => e
      return nil
    end
    response_time = Time.now - start_time
    puts "fetch_secure_offer response time #{response_time} seconds for #{@client.username}"

    if offers && offers[:offers].try(:length).to_i > 0
      offers[:offers].each do |o|
        unless ENV['invalid_offer_ids'].to_s.split(',').include?(o[:offer_id])
          return Offer.find(offer_id: o[:offer_id]).first
        end
      end
    end
    nil
  end

  def fetch_questions
    if Question.all.count == 0
      profile_info = @client.profile_info
      profile_info[:profile_questions].each do |q|
        q[:question_fr] = q[:question_fr].force_encoding('ISO-8859-1').encode('UTF-8')
        Question.create(q)
      end
    end
    Question.all
  end

  def fetch_tos
    data = @client.tos(id: ENV["tos_id"], version: 0)
    Tos.create(data.merge({tos_id: ENV["tos_id"]})) unless Tos.get_tos(version: data[:tos_version])
  end

  def get_entitlement(params={})
    start_time = Time.now
    begin
      #entitlements = {:result_code=>0, :msg_en=>"Success", :msg_fr=>"Success", :msg_dev=>"Entitlements returned successfully. Type recieved: null AdditionalInfo : Source :SalesForce.Failures in flow: Version1 of shomi entitlement service used.Code: 405 [Time Taken: 2983 millisec]", :entitlements=>[{:entitlement=>"shomi", :level=>"ineligible", :code=>"2"}], :accounts=>[{:account_token=>"CAN:230318025507|PROVINCE:ON|TYPE:Cable|FIRSTNAME:GFD|LASTNAME:NHL|", :account_desc_en=>"230318025507(Cable)", :billing_address_province=>"ON", :billing_address_postal_code=>"M2N2P9", :account_desc_fr=>"230318025507(Cable)", :account_type_en=>"SS", :account_type_fr=>"SS", :active=>false}], :optin=>true, :optin_account_token=>"optin_account_token"}
      entitlements = @client.entitlements(ip_address: params[:ip_address], product: ENV['product_list'] ? ENV['product_list'].split(',') : params[:product])
    rescue GodzillaApi::Exception => e
      entitlements = e.error[:result]
    end
    response_time = Time.now - start_time
    puts "get_entitlement response time #{response_time} seconds for #{@client.username}"

    if ENV['product_list'] && entitlements && entitlements[:entitlements]
      entitlement   = entitlements[:entitlements].select { |e| e[:level] == 'purchased' || (e[:level] == 'eligible' && e[:code].to_i == 1) }.try(:first) 
      entitlement ||= entitlements[:entitlements].select { |e| (e[:level] == 'eligible' && e[:code].to_i == 0) }.try(:first) 
    end
    entitlement ||= entitlements[:entitlements].select { |e| e[:entitlement].upcase == ENV['APP_NAME'].upcase }.try(:first) if entitlements && entitlements[:entitlements]
    entitlement.merge!({optin: entitlements[:optin], optin_account_token: entitlements[:optin_account_token]}) if entitlements[:optin]
    accounts = entitlements ? entitlements[:accounts] || [] : []

    return {entitlement: entitlement, accounts: accounts, result_code:  entitlements[:result_code], en: entitlements[:msg_en], fr: entitlements[:msg_fr], dev: entitlements[:msg_dev]}
  end

  def get_orders
    start_time = Time.now
    begin
      orders = @client.userorders
    rescue GodzillaApi::Exception => e
      orders = e.error[:result]
    end
    response_time = Time.now - start_time
    puts "get_orders response time #{response_time} seconds for #{@client.username}"
    orders
  end

  def promo_code?(promo_code)
    @client.promo_code?(promo_code: promo_code)
  end

  def profile_check(email)
    puts "PROFILE CHECK EMAIL #{email}"
    start_time = Time.now
    begin
      result = @client.profile_check(username: email)
    rescue GodzillaApi::Exception => e
      result = e.error[:result]
    end
    response_time = Time.now - start_time
    puts "profile_check response time #{response_time} seconds for #{@client.username}"
    puts "PROFILE CHECK RESPONSE #{result}"
    return result
  end
end
