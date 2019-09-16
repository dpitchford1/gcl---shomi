#
# SsoController is responsible for launching a single sign-on (sso) request
# to a remote site, and for landing an sso request from a remote site.
#
class SsoController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:land]

  #
  # #version returns the version of the sso component of this application.
  #
  def version
    render json: sso_version_json
  end

  #
  # #launch assembles various authentication attributes needed by a remote
  # site to automatically log a user in.  The attributes are digitally signed
  # so that the remote site can verify that the sso request came from a 
  # legitimate source (i.e. us).
  #
  def launch
    case
    when ! valid_launch_request?
      render json: redirect_json(root_path)
    when ! Sso.enabled?
      render json: redirect_json(launch_params[:home_url])
    when currently_logged_in?
      render json: redirect_using_sso_json
    when launch_requires_login?
      render json: redirect_json(new_session_path)
    else
      render json: redirect_json(launch_params[:home_url])
    end
  end

  #
  # #land receives digitally signed authentication attributes from a remote
  # site, verifies the signature and the attributes (e.g. is the username
  # known to us, has the sso request timestamp expired, etc.), and automatically
  # signs the user in.
  #
  def land
    case
    when ! Sso.enabled?
      redirect_to root_path
    when ! Sso.valid_login_request?(land_params)
      redirect_to root_path
    else
      login_using_sso
    end
  end


  #
  # launch support
  #
  private

  def sso_version_json
    { sso_version: SSO_VERSION }.to_json
  end

  def valid_launch_request?
    launch_params[:home_url].present? and 
      launch_params[:sso_url].present? and
      launch_params[:destination_url].present?
  end

  def currently_logged_in?
    @current_session.logged?
  end

  def launch_requires_login?
    !!(launch_params[:requires_login] || '').match(/true/i)
  end

  def redirect_json(url)
    resp_params = {}
    resp_params[:action] = 'redirect_to'
    resp_params[:url]    = url
    resp_params.to_json
  end

  def redirect_using_sso_json
    resp_params = {}
    resp_params[:action]              = 'redirect_using_sso_to'
    resp_params[:sso_version]         = SSO_VERSION
    resp_params[:url]                 = launch_params[:sso_url]
    resp_params[:username]            = @current_session.username
    resp_params[:timestamp]           = Sso.format_timestamp(Time.now)
    resp_params[:guid]                = @current_session.guid
    resp_params[:user_token]          = @current_session.user_token
    resp_params[:language]            = session[:lang].to_s
    resp_params[:destination_url]     = launch_params[:destination_url]
    resp_params[:digital_signature]   = Sso.generate_digital_signature(Sso.build_signable_document(resp_params))
    resp_params.to_json
  end

  def launch_params
    params.permit(:home_url, :sso_url, :destination_url, :requires_login).symbolize_keys
  end


  #
  # land support
  #
  private

  def login_using_sso
    logout
    set_language(land_params[:language])
    create_rails_session(land_params[:language])
    @session = Session.new(land_params)           # Needed so that @current_session works in _navigation.html.erb
    background_notice!(t('sessions.retrieving_info'))
    HardWorker.perform_async(session.id, :sso_login, land_params.merge({ip_address: request.ip, user_region: session[:user_region], home_url: root_path}))
  end

  def logout
    reset_session
    @current_session.delete if @current_session && @current_session.persisted?
  end

  def set_language(language)
    session[:lang] = language                     # Needed by set_locale, below.
    set_locale
  end

  def create_rails_session(language)
    Portal.set_session(session.id, {lang: language})
  end

  def land_params
    params.permit(:sso_version, :username, :timestamp, :guid, :user_token, :digital_signature, :language, :destination_url).symbolize_keys
  end
end
