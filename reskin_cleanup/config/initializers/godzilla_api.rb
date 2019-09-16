GodzillaApi.configure do |config|
  config.record_stubs = :new_episodes #none
  config.use_stubs = false #true
  config.vcr_path = "#{Rails.root}/vcr"
  config.api_key = ENV['api_key']
  config.service_name = ENV['APP_NAME']
  config.version = ENV['api_version']
  config.endpoint = ENV['api_endpoint'] || CONFIG[:api_endpoint]
  config.target = ENV['api_target'] || CONFIG[:api_target]
  config.api_prepend = ENV['api_prepend'] || CONFIG[:api_prepend] || ""
end