class HardWorker
  include Sidekiq::Worker
  include Rails.application.routes.url_helpers
  sidekiq_options :queue => :default, :retry => 2, :backtrace => true

  sidekiq_retry_in { |count| 0*count }

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "RETRIES EXHAUSTED: #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    sid = msg['args'][0]
    session = Portal.get_session(sid)
    background_job = JSON.parse($redis.get("ws:#{sid}")) rescue {}

    # set the session & cleanup background job if it is still active
    if background_job['active']
      # Clean up background job flag
      background_job['active'] = false
      background_job['redirect'] = session[:redirect]
      $redis.setex("ws:#{sid}", 60, JSON.dump(background_job))
      $redis.publish("ws:#{sid}", JSON.dump(background_job))

      session[:notice]      = I18n.t('pages.background.service_unavailable')
      session[:notice_type] = :alert
      session[:sidekiq_attempts] = 0 # reset attempts for the next process
      session[:developer_message] = 'Api timeout'
      begin
        safer_params = msg['args'][2].dup
        safer_params.each do |key,val|
          safer_params[key] = "[FILTERED]" if key =~ /(password|postal|phone|address|street|birthdate)/i
        end
        debug = DebugLog.new(time: Time.now, email: Portal.current_session.try(:username), error_type: 'timeout', api_call: msg['args'][1], parameters: safer_params, developer_message: "Api timeout, worker: #{msg['args'][0]}")
        debug.save
      rescue
      end
      Portal.set_session(sid, session)
    end
  end


  def perform(sid, action, params={})
    I18n.backend.reload!
    session = Portal.get_session(sid)

    Portal.current_session = session[:session] || Session.new
    lang = Portal.current_session.profile ? Portal.current_session.profile.lang_pref : session[:lang]
    lang ||= :en
    I18n.locale = lang

    params.symbolize_keys!

    # Setup API client
    api_client = ApiClient.new(language: lang.to_s)
    api_client.setup(session[:session].attributes) if session[:session] &&  session[:session].logged?

    params.merge!({
      api_client: api_client,
      lang: session[:lang].to_sym || :en
    })

    # count the # of retries this action has gone through to prevent multiple orders from getting sent
    session[:sidekiq_attempts] ||= 0
    session[:sidekiq_attempts] += 1
    Portal.set_session(sid, session)
    Sidekiq.logger.info "TASK: action: #{action}, attempts: #{session[:sidekiq_attempts]}, sid: #{sid}, lang: #{lang}, params: #{output_safe(params)}"

    begin
      Timeout.timeout(100) do
        session = send(action, sid, session, params) if session
      end
    rescue Timeout::Error
      Sidekiq.logger.warn "TIMEOUT: action: #{action}, attempts: #{session[:sidekiq_attempts]}, sid: #{sid}, params: #{output_safe(params)}"
      raise Timeout::Error
    rescue GodzillaApi::ConnectionException => e
      begin
        safer_params = params.dup
        safer_params.delete(:api_client)
        safer_params = api_client.output_safe(safer_params)
        debug = DebugLog.new(time: Time.now, email: Portal.current_session.try(:username), error_type: 'connection', api_call: action, parameters: safer_params, developer_message: e.error[:dev])
        debug.save
      rescue
        return false
      end
      session[:notice], session[:notice_type], session[:developer_message] = [I18n.t('pages.background.service_unavailable'), :alert, e.error[I18n.locale]]
    end

    # Clean up background job flag
    background_job = JSON.parse($redis.get("ws:#{sid}")) rescue {}
    background_job['active'] = false
    background_job['redirect'] = session[:redirect]
    $redis.setex("ws:#{sid}", 60, JSON.dump(background_job))
    $redis.publish("ws:#{sid}", JSON.dump(background_job))

    session[:sidekiq_attempts] = 0 # reset attempts for the next process
    Portal.set_session(sid, session)
  end


  def login(sid, session, params)
    if session[:sidekiq_attempts].to_i == 1 # set entitlement/order history refresh to false for first attempt
      session[:completed_entitlements] = false
      session[:completed_order_history] = false
    end

    s = Session.login(params.merge({promo_code: session[:promo_code]}))
    redirection_params = s.background_params

    # if user has a previous order (cancelled or not, we want to send the user through the apply promo on sign on)
    if ENV['user_orders'] && s.latest_order && session[:promo_code] && PromoCode::REDEMPTION_CODE_TYPES.include?(session[:promo_code].code_type)
      offer_id = if ENV['redemption_top_up']
                   session[:promo_code].premium_redemption? ? ENV['premium_offer_id'] : ENV['basic_offer_id']
                 else
                   ENV['premium_offer_id']
                 end
      order_params = {billing_option: "free", promo_code: session[:promo_code].code, code_type: session[:promo_code].code_type, desc: session[:promo_code].description,
                      offer_id: offer_id, user_is_active: s.profile.try(:eligible?),
                      operation: "update", api_client: params[:api_client], lang: I18n.locale,
                      user_is_on_redemption: s.profile.has_redemption?, order_id: s.latest_order.try(:order_id), term_type: s.profile.term_type }

      apply_redemption_order = Order.new(order_params)
      # only refresh entitlements/order history when the order was successful
      if apply_redemption_order.remote_save(params[:ip_address], s.profile.eligible?, s.profile.has_redemption?, true)
        refresh_entitlements_and_order_history(sid, session, params, s)
      end
      # if the apply promo order was success or error merge the order params to the notice
      redirection_params.merge!(apply_redemption_order.background_params.merge({notice: "#{s.background_params[:notice]} #{apply_redemption_order.background_params[:notice]}"}))
      session[:promo_code] = nil # clear promo code/redemption after order saved
    end

    if ENV['user_orders'] && Admin::FeatureFlag.feature_flag(:redirect_legacy_users) && s.latest_order.nil? && !s.username.include?('@')
      redirection_params[:notice] = I18n.t('sessions.notice.legacy_logged_out').html_safe
      redirection_params[:notice_type] = :alert
      redirection_params[:redirect] = new_session_path
      redirection_params[:signed_in] = 'failed'
      s.delete if s.persisted?
      s = nil
    end

    session[:session] = s
    session.merge!(redirection_params)
    session
  end

  def sso_login(sid, session, params)
    if known_user?(params[:username], params[:api_client])
      s = Session.sso_login(params)
      session[:session] = s
      session.merge!(s.background_params)
      session[:redirect] = params[:destination_url]
    else
      puts "sso: unknown user '#{params[:username]}'"
      session[:redirect] = params[:home_url]
    end
    session
  end

  def forgot_password_email(sid, session, params)
    forgot_password = ForgotPassword.new(params)
    forgot_password.password_hint!
    session.merge!(forgot_password.background_params)
    session[:object] = { forgot_password: forgot_password }
    session
  end

  def forgot_password_answer(sid, session, params)
    forgot_password = ForgotPassword.new(params)
    session[:object] = { forgot_password: forgot_password } unless forgot_password.password_answer?
    session.merge!(forgot_password.background_params)
    session
  end

  def change_password(sid, session, params)
    session = login(sid, session, params)
    session
  end


  def register_and_login(sid, session, params)
    profile = Profile.new(params)
    if s = profile.create_and_login and s.valid?
      session = login(sid, session, params.merge({register_and_login: true}))
      session[:registration] = 'success'
      if ENV['APP_NAME'] == 'nextissue'
        # show different message for redemption register & login
        if session[:promo_code].try(:is_redemption?)
          session[:notice]      = I18n.t('profiles.new_redemption_profile_success')
        else
          session[:redirect] = new_order_path(order: {billing_option:  'cc'})
          session[:notice]      = I18n.t('profiles.new_profile_success')
        end
      end
    else
      session[:registration] = 'failed'
      if ENV['APP_NAME'] == 'nextissue'
        session[:redirect] = new_session_or_new_profile_path(email_address: profile.email_address)

        if profile.background_params[:notice].to_s.match(/email.*already\sin\suse/i).nil?
          # if the error message is not like 'email...already...in...use', then say the system is unavailable
          session[:notice_type] = :alert
          session[:notice] = I18n.t('pages.background.service_unavailable')
          session[:developer_message] = profile.background_params[:developer_message]
        end
      else
        session[:redirect] = new_profile_path
      end

      session[:object]   = { profile: profile }
    end
    session
  end

  def edit_profile(sid, session, params)
    profile = Profile.new(params)
    profile.remote_save
    
    session.merge!(profile.background_params)
    session
  end

  def promo_code?(sid, session, params)
    #validate promo code
    promo_code = PromoCode.check(params)
    promo_code.valid?
    promo_failed_redirection = promo_code.background_params
    if params[:dont_collect_promo_details] && (params[:validate_redemption_only] == "true") #must run through ORDER flow
      if promo_code.is_valid_redemption?
        offer_id = if ENV['redemption_top_up']
                     promo_code.premium_redemption? ? ENV['premium_offer_id'] : ENV['basic_offer_id']
                   else
                     ENV['premium_offer_id']
                   end

        order_params = {billing_option: "free", promo_code: promo_code.code, code_type: promo_code.code_type, desc: promo_code.description,
                        offer_id: offer_id, user_is_active: params[:user_is_active],
                        operation: "update", api_client: params[:api_client], lang: params[:lang],
                        user_is_on_redemption: Portal.current_session.profile.has_redemption?, order_id: params[:latest_order_id], term_type: Portal.current_session.profile.term_type }
        order(sid, session, order_params, true)
      else
        # if the first request ran into timeout, then redirect to account page & show system unavailable try again later
        if session[:sidekiq_attempts].to_i > 1
          promo_failed_redirection = {notice: I18n.t('pages.background.service_unavailable'), notice_type: :alert, redirect: profiles_path}
          order = Order.new(params)
          order.credit_card = session[:credit_card]

          refresh_entitlements_and_order_history(sid, session, params, order)
        else
          promo_failed_redirection = promo_code.background_params
        end
        session.merge!(promo_failed_redirection)
      end
    else #run through normal flow
      session.merge!(promo_failed_redirection)
    end
    session
  end

  def redemption_code?(sid, session, params)
    redemption_code = PromoCode.check(params)
    session.merge!(redemption_code.background_params)
    session
  end

  def email_check(sid, session, params)
    result = Profile.email_check(params)
    if result[:profile_found] == true
      session[:redirect] = new_session_or_new_profile_path(email_address: params[:email_address])
    else
      session[:developer_message] = result[:developer_message] if result[:developer_message]
      session[:redirect] = new_profile_path(email_address: params[:email_address])
    end
    session
  end

  def refresh_entitlements_and_order_history(sid, session, params, order)
    #refresh entitlements and order history
    #This method may get called multiple times due to timeout, so we use flags to keep track of completion
    if !session[:completed_entitlements]
      order.refresh_entitlements 
      session[:completed_entitlements] = true
      Portal.set_session(sid, session)
    end
    
    if !session[:completed_order_history]
      order.refresh_order_history
      session[:completed_order_history] = true
      Portal.set_session(sid, session)
    end
  end

  def order(sid, session, params, add_order_errors_to_notice=false)
    # Only try to process the order for the 1st attempt, after that show service unavailable message
    if session[:sidekiq_attempts].to_i > 1
      order = Order.new(params)
      order.credit_card = session[:credit_card]

      refresh_entitlements_and_order_history(sid, session, params, order)

      session.merge!({notice: I18n.t('pages.background.service_unavailable'), notice_type: :alert, redirect: profiles_path})
    else
      session[:completed_entitlements] = false
      session[:completed_order_history] = false

      order = Order.new(params)
      order.credit_card = session[:credit_card]
      add_order_errors_to_notice = add_order_errors_to_notice || (ENV['APP_NAME'] == 'nextissue' && order.billing_option == 'free')

      #condition for successfull order submission
      if order.remote_save(params[:ip_address], params[:user_is_active], params[:user_is_on_redemption], add_order_errors_to_notice)
        #condition for when we are in the cancel survey flow
        if session[:cancel_survey_promo] && order.promo_code == session[:cancel_survey_promo].code
          order.background_params[:notice] = I18n.t('cancel_order.successfully_applied_promo')
        end

        if ENV['APP_NAME'] == 'nextissue'
          session[:promo_code] = nil # clear promo code/redemption after order saved
        elsif session[:promo_code] && order.billing_option == 'free'
          session[:promo_code].update_attribute(:code_type, 'used')
        end

        # basic redemption user without billing, but selecting premium needs to upgrade to premium, and has chosen rogersbill or cc billing option
        if (order.billing_option != 'free' && params[:currently_on_basic] && !params[:user_has_billing_info] && params[:user_is_active] && params[:user_is_on_redemption]) && params[:offer_id] == ENV["topup_offer_id"]
          # entitlements & order history will be refreshed after the change offer call completes
          change_offer_session = change_offer(sid, session, params.merge({ order_id: order.order_id, existing_offer_type: 'Basic' }))
          # use the change offer notice & type
          order.background_params.merge!({notice: change_offer_session[:notice], notice_type: change_offer_session[:notice_type]})
        else
          #condition for when we are performing a topup
          if params[:topup_on_completion]
            #execute change offer
            change_offer(sid, session, params.merge({existing_offer_type: Portal.current_session.profile.existing_offer_type, offer_id: ENV["topup_offer_id"], user_is_on_redemption: Portal.current_session.profile.has_redemption?, term_type: Portal.current_session.profile.term_type }))
          else
            refresh_entitlements_and_order_history(sid, session, params, order)
          end
        end

      end

      session.merge!(order.background_params)
    end
    session[:object] = { order: order, credit_card: session[:credit_card] }
    session
  end

  def change_offer(sid, session, params)
    if session[:sidekiq_attempts].to_i == 1 # refresh entitlement code & order history status
      session[:completed_entitlements] = false
      session[:completed_order_history] = false
    end
    order = Order.new(params)
    if order.change_offer(params)
      refresh_entitlements_and_order_history(sid, session, params, order)
    end
    session.merge!(order.background_params)
    session[:object] = { order: nil }
    session
  end

  def cancel_order(sid, session, params)
    order = Order.new(params)
    order.cancel_order(params[:billing_cycle_end_date])
    session.merge!(order.background_params)
    session[:object] = { order: nil }
    session
  end

  def link_accounts(sid, session, params)
    account_search = AccountSearch.new(params)
    account_search.link_accounts
    session.merge!(account_search.background_params)
    session[:object] = { account_search: account_search }
    session
  end

  def order_history(sid, session, params)
    order_history = Order.new(params).history

    session[:object] = { order_history: order_history }
    session[:redirect] = billing_path
    session
  end

  def submit_cancellation_survey(sid, session, params)
    session[:cancel_survey_promo] = nil # clear out any previous cancel survey promo
    response = SurveyResult.new(params)

    response.remote_save

    session.merge!(response.background_params)
    session
  end

  def apply_promo_code(sid, session, params)
    if session[:sidekiq_attempts].to_i == 1 # refresh entitlements
      session[:completed_entitlements] = false
      session[:completed_order_history] = true
    end

    order = Order.new(params)
    if order.apply_promo_code
      refresh_entitlements_and_order_history(sid, session, params, order)
    end

    session.merge!(order.background_params)
    session
  end

  private
    def output_safe(params)
      output_params = params.dup

      output_params.each do |key,val|
        output_params[key] = "[FILTERED]" if key =~ /(password|postal|phone|name|address|street|birthdate)/i
      end
      output_params
    end

    def known_user?(email_address, api_client)
      email_check_params = {email_address: email_address, api_client: api_client}
      result = Profile.email_check(email_check_params)
      result[:profile_found]
    end
end
