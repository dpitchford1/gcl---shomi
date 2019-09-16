#
# A colletion of methods to aid single sign-on.  It was created to reduce the
# size of SsoController.
#
# Note that this class is not generic - it knows the specific list of
# parameters (username, timestamp, etc.) used to launch/land sso requests.
#
class Sso

  def self.enabled?
    !!(ENV['sso_enabled'] || 'false').match(/(true|yes)/i)
  end

  def self.build_signable_document(sso_params)
    (sso_params[:sso_version] || '') +
      (sso_params[:username] || '') + 
      (sso_params[:timestamp] || '') +
      (sso_params[:guid] || '') +
      (sso_params[:user_token] || '') +
      (sso_params[:language] || '') +
      (sso_params[:destination_url] || '')
  end

  def self.generate_digital_signature(document)
    DigitalSignature.sign(document, private_key)
  end

  def self.valid_login_request?(sso_params)
    all_params_supplied?(sso_params) and
      valid_sso_digital_signature?(sso_params) and
      valid_sso_timestamp?(sso_params)
  end

  # Convert a timestamp to a string of known format for inclusion in sso
  # requests that are signed, e.g. 2015-03-15T09:27:03.023Z
  #
  # See http://stackoverflow.com/a/15952652
  def self.format_timestamp(timestamp)
    timestamp.utc.strftime('%Y-%m-%dT%H:%M:%S.%LZ')
  end

  def self.timestamp_expiry_seconds
    (ENV['sso_timestamp_expiry_seconds'] || '180').to_i.seconds
  end

  private

  def self.all_params_supplied?(sso_params)
    required_param_names = [:sso_version, :username, :timestamp, :guid, :user_token, :language, :destination_url, :digital_signature]
    supplied_param_names = sso_params.select {|k,v| v.present?}.keys
    all_supplied = (required_param_names - supplied_param_names).empty?
    Rails.logger.warn "sso: missing parameter(s) #{(required_param_names - supplied_param_names).join(', ')}" unless all_supplied
    all_supplied
  end

  def self.valid_sso_digital_signature?(sso_params)
    document = Sso.build_signable_document(sso_params)
    signature = sso_params[:digital_signature]
    valid = DigitalSignature.verify(document, signature, public_key)
    Rails.logger.warn "sso: invalid digital signature" unless valid
    valid
  end

  def self.valid_sso_timestamp?(sso_params)
    valid_timestamp_range = Sso.timestamp_expiry_seconds.ago..Sso.timestamp_expiry_seconds.since
    valid = valid_timestamp_range.cover?(DateTime.parse(sso_params[:timestamp]))
    Rails.logger.warn "sso: invalid timestamp '#{sso_params[:timestamp]}' (time now is #{Sso.format_timestamp(Time.now)})" unless valid
    valid
  end

  def self.private_key
    OpenSSL::PKey::RSA.new( ENV.fetch('single_signon_private_key') )
  end

  def self.public_key
    private_key.public_key()
  end

end
