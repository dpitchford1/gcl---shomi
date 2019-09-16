require_relative '../../test_helper'


class SsoTest < ActiveSupport::TestCase ; end


#
# Sso.enabled? => true/false
#
class SsoTest
  ['true', 'TRUE', 'yes', 'YES'].each do |setting|
    test "#enabled? returns true when ENV['sso_enabled'] is '#{setting}'" do
      ENV['sso_enabled'] = setting
      assert Sso.enabled?
    end
  end

  ['false', 'FALSE', 'no', 'NO', '', '  '].each do |setting|
    test "#enabled? returns false when ENV['sso_enabled'] is '#{setting}'" do
      ENV['sso_enabled'] = setting
      assert ! Sso.enabled?
    end
  end

  test "#enabled? returns false when ENV['sso_enabled'] is nil" do
    ENV['sso_enabled'] = nil
    assert ! Sso.enabled?
  end

  test "#enabled? returns false when ENV['sso_enabled'] is missing" do
    ENV.delete('sso_enabled')
    assert ! Sso.enabled?
  end
end


#
# Sso.build_signable_document(sso_params) => string
#
class SsoTest
  test "#build_signable_document returns a string containing the sso params in the correct order" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: '2015-03-06T18:10:02.123Z', language: 'en', destination_url: '/something'}
    expected_document = '1.2.3a user2015-03-06T18:10:02.123Zdef-456123-abcen/something'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end

  test "#build_signable_document treats a nil sso_version as an empty string" do
    sso_params = { sso_version: nil, username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: '2015-03-06T18:10:02.123Z', language: 'en', destination_url: '/something'}
    expected_document = 'a user2015-03-06T18:10:02.123Zdef-456123-abcen/something'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end

  test "#build_signable_document treats a nil username as an empty string" do
    sso_params = { sso_version: '1.2.3', username: nil, user_token: '123-abc', guid: 'def-456', timestamp: '2015-03-06T18:10:02.123Z', language: 'en', destination_url: '/something'}
    expected_document = '1.2.32015-03-06T18:10:02.123Zdef-456123-abcen/something'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end

  test "#build_signable_document treats a nil timestamp as an empty string" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: nil, language: 'en', destination_url: '/something'}
    expected_document = '1.2.3a userdef-456123-abcen/something'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end

  test "#build_signable_document treats a nil guid as an empty string" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: nil, timestamp: '2015-03-06T18:10:02.123Z', language: 'en', destination_url: '/something'}
    expected_document = '1.2.3a user2015-03-06T18:10:02.123Z123-abcen/something'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end

  test "#build_signable_document treats a nil user_token as an empty string" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: nil, guid: 'def-456', timestamp: '2015-03-06T18:10:02.123Z', language: 'en', destination_url: '/something'}
    expected_document = '1.2.3a user2015-03-06T18:10:02.123Zdef-456en/something'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end

  test "#build_signable_document treats a nil language as an empty string" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: '2015-03-06T18:10:02.123Z', language: nil, destination_url: '/something'}
    expected_document = '1.2.3a user2015-03-06T18:10:02.123Zdef-456123-abc/something'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end

  test "#build_signable_document treats a nil destination_url as an empty string" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: '2015-03-06T18:10:02.123Z', language: 'en', destination_url: nil}
    expected_document = '1.2.3a user2015-03-06T18:10:02.123Zdef-456123-abcen'
    assert_equal expected_document, Sso.build_signable_document(sso_params)
  end
end


#
# Sso.valid_login_request?
#
class SsoTest
  test "#valid_login_request? returns true when all parameters are present" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: Sso.format_timestamp(Time.now), language: 'en', destination_url: '/something'}
    sso_params[:digital_signature] = Sso.generate_digital_signature(Sso.build_signable_document(sso_params))
    assert Sso.valid_login_request?(sso_params)
  end

  [:sso_version, :username, :timestamp, :guid, :user_token, :language, :destination_url, :digital_signature].each do |missing_sso_param_name|
    test "#valid_login_request? returns false when #{missing_sso_param_name} is missing" do
      sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: Sso.format_timestamp(Time.now), language: 'en', destination_url: '/something'}
      sso_params[:digital_signature] = Sso.generate_digital_signature(Sso.build_signable_document(sso_params))
      sso_params.delete(missing_sso_param_name)
      refute Sso.valid_login_request?(sso_params)
    end
  end

  [:sso_version, :username, :timestamp, :guid, :user_token, :language, :destination_url, :digital_signature].each do |missing_sso_param_name|
    test "#valid_login_request? returns false when #{missing_sso_param_name} is nil" do
      sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: Sso.format_timestamp(Time.now), language: 'en', destination_url: '/something'}
      sso_params[:digital_signature] = Sso.generate_digital_signature(Sso.build_signable_document(sso_params))
      sso_params[missing_sso_param_name] = nil
      refute Sso.valid_login_request?(sso_params)
    end
  end

  [:sso_version, :username, :timestamp, :guid, :user_token, :language, :destination_url, :digital_signature].each do |missing_sso_param_name|
    test "#valid_login_request? returns false when #{missing_sso_param_name} is blank" do
      sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: Sso.format_timestamp(Time.now), language: 'en', destination_url: '/something'}
      sso_params[:digital_signature] = Sso.generate_digital_signature(Sso.build_signable_document(sso_params))
      sso_params[missing_sso_param_name] = '  '
      refute Sso.valid_login_request?(sso_params)
    end
  end

  test "#valid_login_request? returns false when the timestamp is invalid" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: Sso.format_timestamp(10.years.ago), language: 'en', destination_url: '/something'}
    sso_params[:digital_signature] = Sso.generate_digital_signature(Sso.build_signable_document(sso_params))
    refute Sso.valid_login_request?(sso_params)
  end

  test "#valid_login_request? returns false when the digital signature is invalid" do
    sso_params = { sso_version: '1.2.3', username: 'a user', user_token: '123-abc', guid: 'def-456', timestamp: Sso.format_timestamp(Time.now), language: 'en', destination_url: '/something'}
    sso_params[:digital_signature] = 'invalid digital signature'
    refute Sso.valid_login_request?(sso_params)
  end
end


#
# Sso.format_timestamp(datetime) => string
#
class SsoTest
  test "#format_timestamp returns a timestamp formatted per ISO 8601" do
    timestamp = Time.new(2015, 03, 06, 21, 51, 23.053, '+00:00')
    assert_equal '2015-03-06T21:51:23.053Z', Sso.format_timestamp(timestamp)
  end
end


#
# Sso.timestamp_expiry_seconds
#
class SsoTest
  test "#timestamp_expiry_seconds returns the sso_timestamp_expiry_seconds variable converted to seconds" do
    ENV['sso_timestamp_expiry_seconds'] = '100'
    assert_equal Sso.timestamp_expiry_seconds, 100.seconds
  end

  test "#timestamp_expiry_seconds returns 180 when ENV['sso_timestamp_expiry_seconds'] is nil" do
    ENV['sso_timestamp_expiry_seconds'] = nil
    assert_equal Sso.timestamp_expiry_seconds, 180.seconds
  end

  test "#timestamp_expiry_seconds returns 180 when ENV['sso_timestamp_expiry_seconds'] is missing" do
    ENV.delete('sso_timestamp_expiry_seconds')
    assert_equal Sso.timestamp_expiry_seconds, 180.seconds
  end
end
