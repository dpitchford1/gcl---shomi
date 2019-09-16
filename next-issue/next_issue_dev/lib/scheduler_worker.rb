class SchedulerWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :scheduler, :retry => false, :backtrace => true

  def perform(action, params = {})
    send(action, params)
  end

  def renew_session(params = {})
    session_id = params['session_id'] || params[:session_id]
    Rails.logger.info "Re-newing session: #{session_id}"
    session = Portal.get_session(session_id)
    if !session or !session[:session] or !session[:session].persisted? or !Session[session[:session].id]
      Portal.delete_session(session_id) if session && session[:session] && session[:session].persisted?
      return
    end
    api_client = ApiClient.new
    api_client.setup(session[:session].attributes)
    info = api_client.profile_info  # Re-new session
    session[:session].user_token = api_client.user_token
    if info && info[:result_code] == 0
      Portal.set_session(session_id, session)
    else
      Portal.delete_session(session_id)
    end
  end

  def get_tos(params = {})
    api_client = ApiClient.new
    api_client.fetch_tos
  end

  def fetch_offers(params = {})
    api_client = ApiClient.new
    api_client.fetch_offers(params)
  end

  def fetch_questions(params = {})
    api_client = ApiClient.new
    api_client.fetch_questions
  end

  def fetch_survey_questions(params = {})
    api_client = ApiClient.new
    api_client.fetch_survey_questions(params)
  end

  def refetch_survey_questions(params={})
    api_client = ApiClient.new
    api_client.refetch_survey_questions(params)
  end

  def db_clean(params = {})
    #iterates over profiles and deletes the profiles and order history that are old
    user_orders = ENV['user_orders']
    Profile.all.each do |p|
      if !p.last_login_attempt || p.last_login_attempt < Time.now - 71.minutes
        p.delete_user_orders if user_orders
        p.delete
      end
    end

    Session.all.each { |s| s.delete unless s.profile }
  end
  
  def promo_code_cache_clear(params = {})
    PromoCode.all.each do |p|
      p.delete
    end
  end

  def feature_flags(params = {})
    Admin::FeatureFlag.timed_toggle
  end

  def debug_log_cleanup(params = {})
    DebugGodzilla.all.each {|d| d.delete }
    DebugLog.all.each {|d| d.delete }
  end

  def user_order_cleanup(params = {})
    Profile.all.each do |p|
      if !p.last_login_attempt || p.last_login_attempt < Time.now - 71.minutes
        p.delete_user_orders
      end
    end
  end
end
