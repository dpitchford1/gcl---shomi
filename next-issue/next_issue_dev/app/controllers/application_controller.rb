class ApplicationController < ActionController::Base
  include CacheableFlash
  
  protect_from_forgery with: :exception, except: [:destroy]
  prepend_view_path "app/views/#{ENV['VIEW_PATH'] || ENV['APP_NAME']}"
  force_ssl if Rails.env.production?

  before_action :ensure_fresh_i18n
  before_action :authenticate, except: [:background_ping]
  before_action :set_no_cache
  before_action :set_locale
  before_action :set_offer
  before_action :set_exclusive_creditcard
  before_action :set_loyalty
  before_action :set_campaign_identifier
  before_action :current_session
  before_action :background_check, except: [:background_ping, :background_cancel, :mercury_update]
  before_action :set_confirmation_type, except: [:background_ping, :background_cancel, :mercury_update]
  after_action :reload_session
  after_action :inject_csrf_token

  def current_session
    # Disable cache for admin user
    ActionController::Base.perform_caching = session[:can_edit] ? false : true unless Rails.env.development?

    Rack::MiniProfiler.authorize_request if ENV['APP_NAME'] != 'nextissue' && Rails.env.staging?
    @current_session = session[:session] || Session.new
    Portal.current_session = @current_session
    @session = @current_session  # For modal sign in
    @current_session
  end


  def background_alt_message!(msg)
    background_job = JSON.parse($redis.get("ws:#{session.id}")) rescue {}
    background_job['alt_message'] = msg
    $redis.setex("ws:#{session.id}", 60, JSON.dump(background_job))
  end

  def background_notice!(msg)
    session[:background_job] = true
    background_job = JSON.dump(
      active: true,
      type: 'background_job',
      message: msg
    )
    $redis.setex("ws:#{session.id}", 60, background_job)
    $redis.publish("ws:#{session.id}", background_job)
  end

  def extract_object(name, cleanup = true)
    if session[:object] && session[:object][name.to_sym]
      cleanup ? session[:object].delete(name.to_sym) : session[:object][name.to_sym]

    end
  end

  private

  def inject_csrf_token
    if protect_against_forgery?
      if body_with_token = response.body.gsub!('__CROSS_SITE_REQUEST_FORGERY_PROTECTION_TOKEN__', view_context.csrf_meta_tags)
        response.body = body_with_token
      end
    end
  end

  def reload_session
    session.merge!(Portal.get_session(session.id)) if session[:background_job]
  end

  def ensure_fresh_i18n
    I18n.backend.reload!
  end

  def set_confirmation_type
    if session[:account_linking]
      session[:confirmation_type] = "account_linking #{session[:account_linking]}"
      session[:account_linking] = nil
    elsif session[:registration]
      session[:confirmation_type] = "registration #{session[:registration] == 'success' && @current_session.profile.entitlement ? @current_session.profile.entitlement['level'] : session[:registration]}" 
      session[:registration] = nil
    elsif session[:signed_in] 
      session[:confirmation_type] = "signin #{session[:signed_in] == 'success' && @current_session.profile.entitlement ? @current_session.profile.entitlement['level'] : session[:signed_in]}" 
      session[:signed_in] = nil
    elsif session[:order_confirmation] 
      session[:confirmation_type] = "order #{session[:order_confirmation]}" 
      session[:order_confirmation] = nil
    end
  end

  def authenticate
    if ENV["enable_http_basic_auth"] == "true" && params[:controller] != "tos" && !session[:can_edit]

      authenticate_or_request_with_http_basic do |username, password|
        username == "gcladmin" && password == "tiger123"
      end
    end
  end

  def background_check
    bj = JSON.parse($redis.get("ws:#{session.id}")) rescue nil

    if bj && !bj['active']
      notice = session.delete(:notice) if session['notice']
      session[:background_job] = false
      flash.now[session['notice_type']] = notice if notice

      $redis.del("ws:#{session.id}")
      if session[:entitlement_failed]
        reset_session
        cookies[:persistent_message] = true
        if ENV['APP_NAME'] == 'nextissue'
          redirect_to new_session_path, alert: notice
        else
          redirect_to root_path(lang: I18n.locale), alert: notice
        end
      end

      if session[:promo_code_invalid]
        flash.now[:notice_is_promo_code] = session.delete(:promo_code_invalid)
      end

      if session[:developer_message]
        flash.now[:developer_message] = session.delete(:developer_message)
      end
    end
  end

  def set_locale
    params[:lang] = params[:locale].gsub(/_CA$/, '') if params[:locale]
    session[:lang] = params[:lang] if params[:lang]
    if session[:lang] == "fr"
      I18n.locale =  :fr
    else
      session[:lang] ||= :en
      I18n.locale = I18n.default_locale
    end
  end

  def set_offer
    if params[:offer_type]
      ot = params[:offer_type]
      if session[:promo_code] && !session[:promo_code].valid_for?(ot)
        ot = session[:promo_code].first_valid_offer_type(ot)
      end
      session[:offer_type] = ot
      session[:offer_id] = ENV["#{ot}_offer_id"] if ENV["#{ot}_offer_id"]
    end
  end

  def set_exclusive_creditcard
    if cookies[:exclusive_creditcard]
      session[:exclusive_creditcard] = cookies[:exclusive_creditcard]
      cookies.delete :exclusive_creditcard, :domain => '.nextissue.ca'
    end
  end

  def set_loyalty
    if cookies[:promoCode] #despite the name it's a loyalty code
      session[:loyalty_code] = nil
      # Setup API client
      api_client = ApiClient.new(language: I18n.locale.to_s)
      api_client.setup(@current_session.attributes) if @current_session.try(:logged?)
      loyalty_check_params = {
          code: cookies[:promoCode], offer_logo_basic_en: cookies[:offerLogoBasic], offer_logo_premium_en: cookies[:offerLogoPremium],
          offer_logo_basic_fr: cookies[:offerLogoBasicFr], offer_logo_premium_fr: cookies[:offerLogoPremiumFr],
          api_client: api_client, current_url: request.url, lang: session[:lang].to_sym || :en
      }
      loyalty_code = LoyaltyCode.check(loyalty_check_params)
      
      if loyalty_code.valid?
        session[:loyalty_code] = loyalty_code
      end
      #delete the cookie
      cookies.delete :promoCode, :domain => '.nextissue.ca'
      cookies.delete :offerLogoBasic, :domain => '.nextissue.ca'
      cookies.delete :offerLogoPremium, :domain => '.nextissue.ca'
    end
  end

  def set_campaign_identifier
    if params[:cid] || cookies[:cid]
      session[:cid] = params[:cid] || cookies[:cid]
      cookies.delete :cid, :domain => '.nextissue.ca'
    end
  end

  def redirect_if_logged(msg = t('sessions.notice.already_logged'))
    redirect_to root_path, notice: msg if current_session.logged?
  end

  def redirect_if_not_logged(msg = t('sessions.notice.must_log'))
    redirect_to root_path, notice: msg unless current_session.logged?
  end

  def set_no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
