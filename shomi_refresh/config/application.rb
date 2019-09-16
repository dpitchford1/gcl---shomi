require File.expand_path('../boot', __FILE__)


require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'
require "rails/test_unit/railtie" if Rails.env.development? or Rails.env.test?

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module DefaultRails
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path = Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s, Rails.root.join('config', 'locales', ENV['APP_NAME'], '*.{rb,yml}').to_s]


    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en, :fr]

    config.autoload_paths << "#{Rails.root}/lib"

    config.assets.paths = [
      Rails.root.join("lib", "assets", "images"),
      Rails.root.join("lib", "assets", "javascripts"),
      Rails.root.join("lib", "assets", "stylesheets"),
      Rails.root.join("lib", "assets", "fonts"),
      Rails.root.join("app", "assets", "images"),
      Rails.root.join("app", "assets", "javascripts"),
      Rails.root.join("app", "assets", "stylesheets"),
      Rails.root.join("app", "assets", ENV['APP_NAME'], "images"),
      Rails.root.join("app", "assets", ENV['APP_NAME'], "javascripts"),
      Rails.root.join("app", "assets", ENV['APP_NAME'], "stylesheets"),
      Rails.root.join("app", "assets", ENV['APP_NAME'], "fonts")
    ]

    config.assets.precompile.pop # Remove default matcher  /(?:\/|\\|\A)application\.(css|js)$/
    config.assets.precompile << /#{ENV['APP_NAME']}\/application\.(css|js)$/

  end
end
