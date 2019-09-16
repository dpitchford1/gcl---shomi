desc "Re-new user siteminder sessions"
task :renew_sessions => :environment do
  puts "Re-newing user sessions..."

  Ohm.redis.call('KEYS', "#{Rails.configuration.session_options[:redis][:key_prefix]}*").each do |key|
    session_id = key.split(':').last
    SchedulerWorker.perform_async(:renew_session, session_id: session_id)
  end
end

desc "Fetching latest TOS"
task :fetch_tos => :environment do
  puts "Fetching TOS..."
  SchedulerWorker.perform_async(:get_tos)
end


desc "Fetching latest offers"
task :fetch_offers, [:product] => [:environment] do |t, args|
  puts "Fetching offers..."
  SchedulerWorker.perform_async(:fetch_offers, product: args[:product])
end


desc "Fetching questions"
task :fetch_questions => :environment do
  puts "Fetching questions..."
  SchedulerWorker.perform_async(:fetch_questions)
end

desc "DB cleanup"
task :db_cleanup => :environment do
  puts "Cleaning DB..."
  SchedulerWorker.perform_async(:db_clean)
end

desc "Promocode cache clear"
task :promo_code_cache_clear => :environment do
  puts "Cleaning promocodes..."
  SchedulerWorker.perform_async(:promo_code_cache_clear)
end

desc "Feature flag on/off"
task :feature_flags => :environment do
  puts "Feature flag on/off..."
  SchedulerWorker.perform_async(:feature_flags)
end