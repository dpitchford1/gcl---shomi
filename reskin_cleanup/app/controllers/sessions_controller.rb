class SessionsController < ApplicationController
  before_action :redirect_if_logged, only: [:new, :create]
  before_action :login_attempts_check, only: [:create]

  def new
    s = extract_object(:session)
    @session = s if s
  end

  def create
    @session = Session.new(session_params)
    profile = Profile.find(username: session_params[:username]).first

    respond_to do |format|
      if ENV['disable_login'] == 'true'
        flash[:alert] = t('errors.try_again')
        format.js { render js: "window.location = '#{root_path}'" }
      elsif profile && profile.login_attempts >= 5
        flash[:alert] = t('sessions.error.locked')
        format.js { render js: "window.location = '#{forgot_password_path}'" }
      elsif @session.valid? && !session_params[:validate]
        background_notice!(t('sessions.retrieving_info'))
        HardWorker.perform_async(session.id, :login, session_params.merge({ip_address: request.ip, user_region: session[:user_region]}))
        format.js { render 'pages/background_job' }
      else
        session[:signed_in] = 'signin failed'
        format.json { render json: {name: @session.class.to_s.underscore, errors: @session.errors.messages } }
      end
    end
  end

  def destroy
    lang = session[:lang]
    reset_session
    @current_session.delete if @current_session.persisted?
    respond_to do |format|
      format.html { redirect_to root_path(lang: lang), notice: t('sessions.notice.logged_out') }
    end
  end

  def background_ping
    response.headers["Access-Control-Allow-Origin"] = "#{request.scheme}://#{request.host}"
    render text: Net::HTTP.get(URI.parse("#{ENV['WEBSOCKETS_HTTP_URL']}/?s=#{params[:s]}")) rescue ''
  end

  def background_cancel
    background_job = JSON.dump(
      active: false,
      type: 'background_job',
      notice: nil,
      alt_message: nil
    )
    $redis.setex("ws:#{session.id}", 60, background_job)
    $redis.publish("ws:#{session.id}", background_job)
    
    session[:redirect] =  nil
    session[:notice_type] = nil
    session[:notice] = nil
    @background_job = false

    redirect_to root_path, notice: t('sessions.notice.cancelled')
  end


  def clear_eligible
    cookies.delete(:eligibility_checked)
    cookies.delete(:portal_eligible)
    destroy #kill session
  end

  private
    def login_attempts_check
      Rails.logger.debug "session_param[:username] == #{session_params[:username]}"
      profile = Profile.find(username: session_params[:username]).first
      profile ? Rails.logger.debug("profile.username == #{profile.username}") : Rails.logger.debug("login_attempts_check profile not found")
      profile.update_attribute(:login_attempts, 0) if profile && profile.last_login_attempt && profile.last_login_attempt + 5.minutes < Time.now
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def session_params
      params.require(:session).permit(:lang, :username, :password, :validate).symbolize_keys
    end
end
