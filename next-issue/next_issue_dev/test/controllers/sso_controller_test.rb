require 'test_helper'


class SsoControllerTest < ActionController::TestCase ; end


#
# SsoController#version
#
class SsoControllerTest
  test "#version returns the SSO version" do
    get :version
    assert_equal SSO_VERSION, launch_resp_params['sso_version']
  end
end


#
# SsoController#launch
#
class SsoControllerTest
  test "#launch redirects to the home page when home_url is missing" do
    enable_sso()
    logout()
    post :launch, launch_req_params({'home_url' => nil}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal root_path, launch_resp_params['url']
  end

  test "#launch redirects to the home page when home_url is blank" do
    enable_sso()
    logout()
    post :launch, launch_req_params({'home_url' => '  '}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal root_path, launch_resp_params['url']
  end

  test "#launch redirects to the home page when sso_url is missing" do
    enable_sso()
    login()
    post :launch, launch_req_params({'sso_url' => nil}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal root_path, launch_resp_params['url']
  end

  test "#launch redirects to the home page when sso_url is blank" do
    enable_sso()
    login()
    post :launch, launch_req_params({'sso_url' => '  '}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal root_path, launch_resp_params['url']
  end

  test "#launch redirects to the home page when destination_url is missing" do
    enable_sso()
    login()
    post :launch, launch_req_params({'destination_url' => nil}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal root_path, launch_resp_params['url']
  end

  test "#launch redirects to the home page when destination_url is blank" do
    enable_sso()
    login()
    post :launch, launch_req_params({'destination_url' => '  '}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal root_path, launch_resp_params['url']
  end

  test "#launch defaults requires_login parameter to false when it is missing" do
    enable_sso()
    logout()
    post :launch, launch_req_params({'requires_login' => nil}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal launch_req_params['home_url'], launch_resp_params['url']
  end

  test "#launch redirects to the regular url when the user is not logged in and requires_login is false" do
    enable_sso()
    logout()
    post :launch, launch_req_params({'requires_login' => 'false'}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal launch_req_params['home_url'], launch_resp_params['url']
  end

  test "#launch redirects to the signin url when the user is not logged in and requires_login is true" do
    enable_sso()
    logout()
    post :launch, launch_req_params({'requires_login' => 'true'}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal new_session_path, launch_resp_params['url']
  end

  test "#launch redirects using sso when the user is logged in and requires_login is false" do
    enable_sso()
    login()
    post :launch, launch_req_params({'requires_login' => 'false'}), launch_req_headers
    assert_equal 'redirect_using_sso_to', launch_resp_params['action']
  end

  test "#launch redirects using sso when the user is logged in and requires_login is true" do
    enable_sso()
    login()
    post :launch, launch_req_params({'requires_login' => 'true'}), launch_req_headers
    assert_equal 'redirect_using_sso_to', launch_resp_params['action']
  end

  test "#launch returns the correct sso attributes" do
    freeze_time do
      enable_sso()
      stub_session = login()
      post :launch, launch_req_params, launch_req_headers
      assert_equal SSO_VERSION, launch_resp_params['sso_version']
      assert_equal stub_session.username, launch_resp_params['username']
      assert_equal Sso.format_timestamp(Time.now), launch_resp_params['timestamp']
      assert_equal stub_session.guid, launch_resp_params['guid']
      assert_equal stub_session.user_token, launch_resp_params['user_token']
      assert_equal @controller.session[:lang].to_s, launch_resp_params['language']
      assert_equal launch_req_params['destination_url'], launch_resp_params['destination_url']
    end
  end

  test "#launch returns the correct digital signature" do
    freeze_time do
      enable_sso()
      stub_session = login()
      post :launch, launch_req_params, launch_req_headers
      document = Sso.build_signable_document(build_launch_params(stub_session, @controller.session, launch_req_params['destination_url']))
      expected_digital_signature = Sso.generate_digital_signature(document)
      assert_equal expected_digital_signature, launch_resp_params['digital_signature']
    end
  end

  test "#launch redirects to the regular url when sso is disabled and the user is not logged in" do
    disable_sso()
    logout()
    post :launch, launch_req_params, launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal launch_req_params['home_url'], launch_resp_params['url']
  end

  test "#launch redircts to the regular url when sso is disabled and the user is logged in" do
    disable_sso()
    login()
    post :launch, launch_req_params({'requires_login' => 'false'}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal launch_req_params['home_url'], launch_resp_params['url']
  end

  test "#launch redirects to the regular url when sso is disabled, the user is not logged in, and require_login is true" do
    disable_sso()
    logout()
    post :launch, launch_req_params({'requires_login' => 'true'}), launch_req_headers
    assert_equal 'redirect_to', launch_resp_params['action']
    assert_equal launch_req_params['home_url'], launch_resp_params['url']
  end
end


#
# SsoController#land
#
class SsoControllerTest
  test "#land redirects to the home page when sso is disabled" do
    disable_sso()
    post :land, land_params
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when the sso digital signature is invalid" do
    enable_sso()
    post :land, land_params_with_invalid_signature
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when the sso timestamp is more than Sso.timestamp_expiry_seconds old" do
    enable_sso()
    set_timestamp_expiry_seconds(100.seconds)
    post :land, land_params_with_expired_timestamp(101.seconds)
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when the sso timestamp is more than Sso.timestamp_expiry_seconds in the future" do
    enable_sso()
    set_timestamp_expiry_seconds(100.seconds)
    post :land, land_params_with_future_timestamp(101.seconds)
    assert_redirected_to root_path
  end

  # TODO: no longer know how to test this.
  # test "#land redirects to the home page when the sso user is unknown" do
  #   enable_sso()
  #   post :land, land_params_with_unknown_username
  #   assert_redirected_to root_path
  # end

  test "#land redirects to the home page when username is missing" do
    enable_sso()
    post :land, land_params_with_missing_username
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when timestamp is missing" do
    enable_sso()
    post :land, land_params_with_missing_timestamp
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when guid is missing" do
    enable_sso()
    post :land, land_params_with_missing_guid
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when user_token is missing" do
    enable_sso()
    post :land, land_params_with_missing_user_token
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when language is missing" do
    enable_sso()
    post :land, land_params_with_missing_language
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when destination_url is missing" do
    enable_sso()
    post :land, land_params_with_missing_destination_url
    assert_redirected_to root_path
  end

  test "#land redirects to the home page when digital_signature is missing" do
    enable_sso()
    post :land, land_params_with_missing_digital_signature
    assert_redirected_to root_path
  end

  test "#land invokes SessionController#sso when the sso login params are valid" do
    enable_sso()
    @controller.stubs(:background_notice!)
    HardWorker.expects(:perform_async).with(anything, :sso_login, anything)
    post :land, land_params
  end

  test "#land invokes background_notice! when the sso login params are valid" do
    enable_sso()
    HardWorker.stubs(:perform_async)
    @controller.expects(:background_notice!)
    post :land, land_params
  end
  
  test "#land returns the sso landing page if sso is successful" do
    enable_sso()
    logout()
    @controller.stubs(:background_notice!)
    post :land, land_params
    assert_template :land
  end
end


#
# Test support methods.
#
class SsoControllerTest
  private

  # Regarding _csrf_token, see http://stackoverflow.com/a/26472245
  def launch_req_params(overrides = {})
    session[:_csrf_token] = SecureRandom.base64(32)
    {
      'home_url'            => 'http://www.example.com', 
      'sso_url'             => 'http://www.example.com/sso', 
      'destination_url'     => '/something',
      'requires_login'      => 'false',
      'authenticity_token'  => session[:_csrf_token]
    }.merge(overrides)
  end

  def launch_req_headers
    {
      'ACCEPT'        => 'application/json', 
      'CONTENT_TYPE'  => 'application/json'
    }
  end

  def launch_resp_params
    JSON.parse(@response.body)
  end

  def land_params(overrides = {})
    land_params = {
      sso_version: SSO_VERSION,
      username: known_username,
      timestamp: Sso.format_timestamp(Time.now),
      guid: 'a guid',
      user_token: 'a user token',
      language: 'en',
      destination_url: '/something'
    }.merge(overrides)
    land_params[:digital_signature] = Sso.generate_digital_signature(Sso.build_signable_document(land_params))
    land_params
  end

  def land_params_with_invalid_signature
    land_params = land_params()
    land_params[:digital_signature] = Sso.generate_digital_signature('some other document')
    land_params
  end

  def land_params_with_missing_username
    land_params({
      username: nil
    })
  end

  def land_params_with_unknown_username
    land_params({
      username: unknown_username
    })
  end

  def land_params_with_missing_timestamp
    land_params({
      timestamp: nil
    })
  end

  def land_params_with_expired_timestamp(timestamp_expiry)
    land_params({
      timestamp: Sso.format_timestamp(timestamp_expiry.ago)
    })
  end

  def land_params_with_future_timestamp(timestamp_expiry)
    land_params({
      timestamp: Sso.format_timestamp(timestamp_expiry.since)
    })
  end

  def land_params_with_missing_guid
    land_params({
      guid: nil
    })
  end

  def land_params_with_missing_user_token
    land_params({
      user_token: nil
    })
  end

  def land_params_with_missing_language
    land_params({
      language: nil
    })
  end

  def land_params_with_missing_destination_url
    land_params({
      destination_url: nil
    })
  end

  def land_params_with_missing_digital_signature
    land_params = land_params()
    land_params[:digital_signature] = nil
    land_params
  end

  def login
    stub_session = Struct.new(:logged?, :persisted?, :username, :guid, :user_token).new(true, true, 'a username', 'a guid', 'a user_token')
    @controller.stubs(:current_session).returns(stub_session)
    @controller.instance_variable_set(:@current_session, stub_session)
    @controller.session[:lang] = 'fr'
    stub_session
  end

  def logout
    stub_session = Struct.new(:logged?, :persisted?, :username, :guid, :user_token).new(false, false, nil, nil, nil)
    @controller.stubs(:current_session).returns(stub_session)
    @controller.instance_variable_set(:@current_session, stub_session)
    @controller.session[:lang] = 'en'
    stub_session
  end

  def known_username
    @known_user ||= Profile.all.first.username
  end

  def unknown_username
    "unknown_username#{Time.now.to_i}"    # generate a name that is unlikely to already exist
  end

  def enable_sso
    ENV['sso_enabled'] = 'true'
  end

  def disable_sso
    ENV['sso_enabled'] = 'false'
  end

  def set_timestamp_expiry_seconds(timestamp_expiry_seconds)
    Sso.stubs(:timestamp_expiry_seconds).returns(timestamp_expiry_seconds)
  end

  def build_launch_params(session, controller_session, destination_url)
    {
      sso_version: SSO_VERSION,
      username: session.username,
      timestamp: Sso.format_timestamp(Time.now),
      guid: session.guid,
      user_token: session.user_token,
      language: controller_session[:lang].to_s,
      destination_url: destination_url
    }
  end

  def freeze_time
    frozen_time = Time.now
    Time.stubs(:now).returns(frozen_time)
    yield
  ensure
    Time.unstub(:now)
  end
end
