# bundle exec rake show_me_errors[nextissue_2015-04-06_130225_2015-04-13_130225.log]

desc "count errors in heroku logs (put log file in tmp folder), rake show_me_errors[file_name]"
task :show_me_errors, [:file_path]  => :environment do |t, args|
  date_today = Date.today.strftime('%d-%m-%Y')
  error_count = 0
  no_route_count = 0
  sf_error_count = 0
  begin

    File.open(Rails.root.join('tmp', "route_errors_#{date_today}.txt"), 'w+') do |no_route|
      File.open(Rails.root.join('tmp', "salesforce_errors_#{date_today}.txt"), 'w+') do |er_sf_output|
        File.open(Rails.root.join('tmp', "errors_#{date_today}.txt"), 'w+') do |output|
          # split errors into separate files
          File.open(Rails.root.join('tmp', args[:file_path]), 'r') do |log|
            log.each_line do |line|
              if line.match(/error/i)
                error_count += 1
                output << "error: #{error_count}, \n#{line.inspect}\n"
              end
            end
          end

          # add the past few lines & the error line itself (to show the order input)
          log_arr = IO.readlines(Rails.root.join('tmp', args[:file_path]))
          log_arr.each_with_index do |line, index|
            if line.match(/No route matches /i)
              no_route_count += 1
              no_route << "\n==== ==== ==== ==== ==== ==== ==== ==== count: #{no_route_count}==== ==== ==== ==== ==== ==== ==== ==== \n"
              no_route << "\n#{line.inspect}\n"
            end

            if line.match(/error.*salesforce/i)
              sf_error_count += 1
              er_sf_output << "\n==== ==== ==== ==== ==== ==== ==== ==== count: #{sf_error_count}==== ==== ==== ==== ==== ==== ==== ==== \n"
              er_sf_output << "#{log_arr[index - 8].inspect}\n\n"
              er_sf_output << "#{log_arr[index - 7].inspect}\n\n"
              er_sf_output << "#{log_arr[index - 6].inspect}\n\n"
              er_sf_output << "#{log_arr[index - 5].inspect}\n\n"
              er_sf_output << "#{log_arr[index - 4].inspect}\n\n"
              er_sf_output << "#{log_arr[index - 3].inspect}\n\n"
              er_sf_output << "#{log_arr[index - 2].inspect}\n\n"
              er_sf_output << "#{log_arr[index - 1].inspect}\n\n"
              er_sf_output << "\n#{line.inspect}\n"
            end
          end
        end
      end
    end

  rescue Exception => e
    puts "exception: #{e.inspect}"
  end
end
