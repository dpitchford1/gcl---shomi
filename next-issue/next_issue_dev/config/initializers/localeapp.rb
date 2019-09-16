require 'localeapp/rails'


if defined?(Rails)
  Localeapp.configure do |config|
    config.api_key = ENV['LOCALEAPP_API_KEY']
    config.translation_data_directory = "#{Rails.root}/config/locales/#{ENV['APP_NAME']}"
    config.poll_interval = 30
    config.sending_environments = []
  end
end