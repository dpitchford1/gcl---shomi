class HardWorker
  include Sidekiq::Worker
  include Rails.application.routes.url_helpers
  sidekiq_options :queue => :default, :retry => 2, :backtrace => true

  sidekiq_retry_in { |count| 0*count }

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "RETRIES EXHAUSTED: #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
    sid = msg['args'][0]
    session = Portal.get_session(sid)

    # Clean up background job flag
    background_job = JSON.parse($redis.get("ws:#{sid}")) rescue {}
    background_job['active'] = false
    background_job['redirect'] = session[:redirect]
    $redis.setex("ws:#{sid}", 60, JSON.dump(background_job))
    $redis.publish("ws:#{sid}", JSON.dump(background_job))

    session[:notice]      = I18n.t('pages.background.service_unavailable')
    session[:notice_type] = :alert
    Portal.set_session(sid, session)
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

    Sidekiq.logger.info "TASK: action: #{action}, sid: #{sid}, lang: #{lang}, params: #{output_safe(params)}"
    begin
      Timeout.timeout(30) do
        session = send(action, sid, session, params) if session
      end
    rescue Timeout::Error
      Sidekiq.logger.warn "TIMEOUT: action: #{action}, sid: #{sid}, params: #{output_safe(params)}"
      raise Timeout::Error
    end

    # Clean up background job flag
    background_job = JSON.parse($redis.get("ws:#{sid}")) rescue {}
    background_job['active'] = false
    background_job['redirect'] = session[:redirect]
    $redis.setex("ws:#{sid}", 60, JSON.dump(background_job))
    $redis.publish("ws:#{sid}", JSON.dump(background_job))

    Portal.set_session(sid, session)
  end


  def login(sid, session, params)
    s = Session.login(params.merge({promo_code: session[:promo_code]}))
    session[:session] = s
    session.merge!(s.background_params)
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
      session = login(sid, session, params)
      session[:registration] = 'success'
    else
      session[:registration] = 'failed'
      session[:redirect] = new_profile_path
      session[:object]   = { profile: profile }
    end
    session
  end


  def promo_code?(sid, session, params)
    promo_code = PromoCode.check(params)
    session.merge!(promo_code.background_params)
    session
  end

  def order(sid, session, params)
    order = Order.new(params)
    order.credit_card = session[:credit_card]
    if order.remote_save
      session[:promo_code].update_attribute(:code_type, 'used') if session[:promo_code] && order.billing_option == 'free'
    end
    session.merge!(order.background_params)
    session[:object] = { order: order, credit_card: session[:credit_card] }
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

  private
    def output_safe(params)
      output_params = params.dup

      output_params.each do |key,val|
        output_params[key] = "[FILTERED]" if key =~ /(password|postal|phone|name|address|street|birthdate)/i
      end
      output_params
    end
end
