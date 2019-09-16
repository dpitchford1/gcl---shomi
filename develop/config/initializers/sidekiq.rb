require 'sidekiq/web'

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == ["admin", ENV['admin_password']]
end

Sidekiq.options[:concurrency] = ENV["SIDEKIQ_CONCURRENCY"].to_i || 25


redis_config = {
  url: ENV["REDISCLOUD_SIDEKIQ_URL"]
}  

Sidekiq.configure_server do |config|
    config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV["REDISCLOUD_SIDEKIQ_URL"],
    size: 2
  }
end
