class ApplicationController < ActionController::Base
  include CacheableFlash
  
  protect_from_forgery with: :exception, except: [:destroy]
  prepend_view_path "app/views/#{ENV['APP_NAME']}"
  force_ssl if Rails.env.production?

  before_action :ensure_fresh_i18n
  before_action :authenticate, except: [:background_ping]
  before_action :set_no_cache
  before_action :set_locale
  before_action :current_session
  before_action :background_check, except: [:background_ping, :background_cancel, :mercury_update]
  before_action :set_confirmation_type, except: [:background_ping, :background_cancel, :mercury_update]
  after_action :reload_session
  after_action :inject_csrf_token

  def current_session
    # Disable cache for admin user
    ActionController::Base.perform_caching = session[:can_edit] ? false : true unless Rails.env.development?

    Rack::MiniProfiler.authorize_request if Rails.env.staging?
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
        redirect_to root_path(lang: I18n.locale), alert: notice 
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
