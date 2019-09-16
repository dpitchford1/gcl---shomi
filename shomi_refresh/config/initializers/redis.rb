if ENV["REDISCLOUD_URL"]
  $redis = Redis.new(:url => ENV["REDISCLOUD_URL"])
else
  $redis = Redis.new(:host => 'localhost', :port => 6379)
end
REDIS_URI = ENV["REDISCLOUD_URL"] ? URI.parse(ENV["REDISCLOUD_URL"]) : nil

Ohm.redis = Redic.new(ENV["REDISCLOUD_URL"])

OPTIN_REDIS =  Redis.new(:url => ENV["REDISCLOUD_OPTIN"])

