class ApiClient
  attr_accessor :client

  def initialize(params={})
    @client ||= GodzillaApi::Client.new(params)
  end

  def setup(params)
    params.symbolize_keys!
    @client.username      = params[:username]
    @client.password      = params[:password]
    @client.user_id       = params[:username]
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

  def siteminder_login_with_smsession(params)
    start_time = Time.now
    result = @client.siteminder_login_with_smsession(params)
    response_time = Time.now - start_time
    puts "siteminder_login_with_smsession response time #{response_time} seconds for #{@client.username}"
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

  def cancel_order(params)
    start_time = Time.now
    cancel_order = @client.cancel_order(params)
    response_time = Time.now - start_time
    puts "cancel_order response time #{response_time} seconds for #{@client.username}"
    return cancel_order
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

  def fetch_survey_questions(params={})
    params.symbolize_keys!
    survey_type = (params[:survey_type] || params['survey_type']).to_s.downcase

    if SurveyQuestion.find(survey_type: survey_type).count == 0
      results = @client.get_survey_questions(params)
      survey_id = results[:id]

      results[:questions].each do |q|
        question = SurveyQuestion.create({ survey_type: survey_type, survey_id: survey_id, question_id: q[:id], desc_en: q[:label_en], desc_fr: q[:label_fr].force_encoding('ISO-8859-1').encode('UTF-8') })
        if question && q[:choices]
          q[:choices].each do |c|
            question.survey_options << SurveyOption.create(c.merge( { question_id: question.question_id, option_id: c[:value], desc_en: c[:label_en], desc_fr: c[:label_fr].force_encoding('ISO-8859-1').encode('UTF-8') } ))
          end
        end
      end
    end
    SurveyOption.all
  end

  def refetch_survey_questions(params={})
    survey_type = (params[:survey_type] || params['survey_type']).to_s.downcase
    if SurveyQuestion.find(survey_type: survey_type).count > 0
      SurveyQuestion.find(survey_type: survey_type).each do |question|
        question.survey_options.each do |option|
          option.delete
        end
        question.delete
      end
    end

    fetch_survey_questions(params)
  end

  def fetch_tos
    # Save tos for each version & id in the environment
    tos_ids = ENV['tos_id'].to_s.split(',')
    versions = ENV['tos_version_list'].to_s.split(',')
    
    tos_ids.each_with_index do |tos_id, index|
      version = versions[index].blank? ? '0' : versions[index]
      begin
        data = @client.tos({version: version, id: tos_id})
        Tos.create(data.merge({tos_id: tos_id})) unless Tos.get_tos(version: data[:tos_version], id: tos_id)
        puts "tos saved for tos_id = #{tos_id.inspect}, version = #{version.inspect}"
      rescue GodzillaApi::Exception => e
        puts "Godzilla error saving tos_id = #{tos_id.inspect}, version = #{version.inspect}\n"
        puts e.error[:result].inspect
        log_godzilla_exception({api_call: '/gettermsandconditions', parameters: {version: version, id: tos_id}.to_s, developer_message: "e.error: #{e.error.inspect}"})
      end
    end
  end

  def get_entitlement(params={})
    start_time = Time.now
    begin
      entitlements = @client.entitlements(ip_address: params[:ip_address], product: ENV['product_list'] ? ENV['product_list'].split(',') : params[:product])
    rescue GodzillaApi::Exception => e
      entitlements = e.error[:result]
      log_godzilla_exception({api_call: '/entitlements', parameters: params, developer_message: "e.error: #{e.error.inspect}"})
    end

    response_time = Time.now - start_time
    puts "get_entitlement response time #{response_time} seconds for #{@client.username}"

    if ENV['product_list'] && entitlements && entitlements[:entitlements]
      entitlement   = entitlements[:entitlements].select { |e| e[:level] == 'purchased' || (e[:level] == 'eligible' && e[:code].to_i == 1) }.try(:first) 
      entitlement ||= entitlements[:entitlements].select { |e| (e[:level] == 'eligible' && e[:code].to_i == 0) }.try(:first) 
    end
    entitlement ||= entitlements[:entitlements].select { |e| e[:entitlement].upcase == ENV['APP_NAME'].upcase }.try(:first) if entitlements && entitlements[:entitlements]
    entitlement.merge!({optin: entitlements[:optin], optin_account_token: entitlements[:optin_account_token]}) if entitlements[:optin]
    entitlement.merge!({user_has_billing_info: entitlements[:user_has_billing_info]}) if entitlements[:user_has_billing_info]
    entitlement.merge!({term_type: entitlements[:term_type]}) if entitlements[:term_type]

    accounts = entitlements ? entitlements[:accounts] || [] : []

    # convert French promo description to valid utf8 characters
    if entitlement[:promo_data]
      entitlement[:promo_data] = entitlement[:promo_data].merge({promo_desc: entitlement[:promo_data][:promo_desc].to_s.to_valid_utf8})
    end

    # Convert 'VIA Pr\xE9f\xE9rence' to valid utf-8 characters before saving the entitlements
    entitlement[:loyalty_data][:loyalty_type] = entitlement[:loyalty_data][:loyalty_type].to_s.to_valid_utf8 if entitlement[:loyalty_data]

    return {entitlement: entitlement, accounts: accounts, result_code:  entitlements[:result_code], en: entitlements[:msg_en], fr: entitlements[:msg_fr], dev: entitlements[:msg_dev], account_summary_token: entitlements[:account_summary_token]}
  end

  def get_orders(params = {})
    start_time = Time.now
    begin
      orders = @client.userorders(params)
    rescue GodzillaApi::Exception => e
      orders = e.error[:result]
      if orders[:msg_dev].match(/order\shistory.*null/i).nil? # don't log empty order history errors
        log_godzilla_exception({api_call: '/userorders', parameters: params, developer_message: "e.error: #{e.error.inspect}"})
      end
    end

    response_time = Time.now - start_time
    puts "get_orders response time #{response_time} seconds for #{@client.username}"

    orders[:orders] = [] if orders[:result_code] == -1

    address = orders[:address1].to_s.to_valid_utf8.split("\n")
    user_address_info = {street: address[0], address2: address[1], city: orders[:city].to_s.to_valid_utf8, province: orders[:province].to_s.to_valid_utf8, postal_code: orders[:postal_code].to_s.to_valid_utf8}
    loyalty_type = orders[:loyalty_partner].to_s.to_valid_utf8
    user_orders = []
    orders[:orders].each do |o|
      user_orders << o.merge(user_address_info).merge(masked_cc: o[:masked_cc_num]).merge({membership_number: orders[:membership_number], loyalty_partner: loyalty_type, full_name: o[:full_name].to_s.to_valid_utf8})
    end

    return {user_orders: user_orders, result_code: orders[:result_code], en: orders[:desc_en], fr: orders[:desc_fr]}
  end

  def get_promo_code_history(params={})
    start_time = Time.now
    begin
      promo_codes = @client.get_promo_code_history(params)
    rescue GodzillaApi::Exception => e
      promo_codes = e.error[:result]
      if promo_codes[:msg_dev].match(/PromoCode\shistory.*null/i).nil? # don't log empty promo code history errors
        log_godzilla_exception({api_call: '/promocodehistory', parameters: params, developer_message: "e.error: #{e.error.inspect}"})
      end
    end

    response_time = Time.now - start_time
    puts "get_promo_code_history response time #{response_time} seconds for #{@client.username}"

    # convert French promo description to valid utf8 characters
    valid_promo_data = []
    if !promo_codes[:promo_data].nil? && !promo_codes[:promo_data].empty?
      promo_codes[:promo_data].each do |pd|
        valid_promo_data << pd.merge({promo_desc: pd[:promo_desc].to_s.to_valid_utf8})
      end
    end

    {history: valid_promo_data, result_code: promo_codes[:result_code], en: promo_codes[:msg_en], fr: promo_codes[:msg_fr]}
  end

  def promo_code?(promo_code)
    @client.promo_code?(promo_code: promo_code)
  end

  def loyalty_code?(loyalty_code)
    @client.loyalty_code?(loyalty_code: loyalty_code)
  end

  def profile_check(email)
    puts "PROFILE CHECK EMAIL #{email}"
    start_time = Time.now
    begin
      result = @client.profile_check(username: email)
    rescue GodzillaApi::Exception => e
      result = e.error[:result]
      log_godzilla_exception({api_call: '/profile_check', parameters: email, developer_message: "e.error: #{e.error.inspect}"})
    end
    response_time = Time.now - start_time
    puts "profile_check response time #{response_time} seconds for #{@client.username}"
    puts "PROFILE CHECK RESPONSE #{result}"
    return result
  end

  def change_offer(params)
    start_time = Time.now
    begin
      result = @client.change_offer(params)
    rescue GodzillaApi::Exception => e
      result = e.error[:result]
      log_godzilla_exception({api_call: '/changeoffer', parameters: params, developer_message: "e.error: #{e.error.inspect}"})
    end
    response_time = Time.now - start_time
    puts "change_offer response time #{response_time} seconds for #{@client.username}"    

    return result
  end

  def submit_cancellation_survey(params)
    puts "\nsubmit cancellation survey params: #{params.inspect}\n\n"
    start_time = Time.now
    begin
      result = @client.submit_cancel_survey_response(params)
    rescue GodzillaApi::Exception => e
      result = e.error[:result]
      log_godzilla_exception({api_call: '/survey_response', parameters: params, developer_message: "e.error: #{e.error.inspect}"})
    end
    response_time = Time.now - start_time
    puts "submit_cancellation_survey response time #{response_time} seconds for #{@client.username}"

    return result
  end

  def apply_promo_code(params)
    start_time = Time.now
    begin
      result = @client.apply_promo_code(params)
    rescue GodzillaApi::Exception => e
      result = e.error[:result]
      log_godzilla_exception({api_call: '/apply_promo_code', parameters: params, developer_message: "e.error: #{e.error.inspect}"})
    end
    response_time = Time.now - start_time
    puts "apply_promo_code response time #{response_time} seconds for #{@client.username}"

    return result
  end

  def log_godzilla_exception(attr={})
    begin
      if Admin::FeatureFlag.feature_flag(:log_godzilla_exceptions)
        debug = DebugGodzilla.new({time: Time.now, error_type: 'godzilla exception', email: @client.username}.merge(attr))
        debug.save
      end
    rescue
      return false
    end
  end

  def output_safe(params)
    if @client.output_safe_flag
      output_params = params.dup

      output_params.each do |key,val|
        output_params[key] = "[FILTERED]" if key.to_s =~ /(password|postal_code|phone|first_name|last_name|full_name|province|street|birthdate)/i
      end
      output_params
    else
      params
    end
  end
end
