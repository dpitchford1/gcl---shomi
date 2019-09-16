# Be sure to restart your server when you modify this file.

DefaultRails::Application.config.session_store :redis_session_store, {
  key: '_default_rails_session',
  redis: {
    db: REDIS_URI ? REDIS_URI.path.gsub("/", "") : 0,
    expire_after: 60.minutes,
    key_prefix: 'gcl:session:',
    host: REDIS_URI ? REDIS_URI.host : 'localhost',
    port: REDIS_URI ? REDIS_URI.port : 6379,
    password: REDIS_URI ? REDIS_URI.password : nil

  }
}
