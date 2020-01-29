rails_env = ENV["RAILS_ENV"] || 'integration'
hostname = `hostname`.strip

puts ">> Executing bluepill @#{hostname} with RAILS_ENV=#{rails_env}"
`mkdir -p /clients/sportsnet/gamecentrelive.rogers.com/shared/pids/gcl-#{hostname}`

Bluepill.application("gcl-#{hostname}", base_dir: "/clients/sportsnet/gamecentrelive.rogers.com/shared", log_file: "/clients/sportsnet/gamecentrelive.rogers.com/shared/log/bluepill-#{hostname}.log") do |app|
  app.working_dir = "/clients/sportsnet/gamecentrelive.rogers.com/current"
  app.process("sidekiq") do |process|

     
    process.pid_file = pidfile
    process.start_command = "sidekiq -q default -q scheduler -e #{rails_env} -P #{pidfile} -d  -L /clients/sportsnet/gamecentrelive.rogers.com/shared/log/sidekiq.log "
    process.stop_command = "sidekiqctl stop #{pidfile}"

    process.start_grace_time = 30.seconds
    process.stop_grace_time = 30.seconds
    process.restart_grace_time = 45.seconds
    process.stop_signals = [:term, 10.seconds, :term, 15.seconds, :kill]

    process.uid = "sportsnet"
    process.gid = "sportsnet"
    end
end
