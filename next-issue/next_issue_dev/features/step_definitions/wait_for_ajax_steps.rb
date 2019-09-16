def wait_for_ajax
  begin
    Timeout.timeout(Capybara.default_wait_time) do
      loop until finished_all_ajax_requests?
    end
  rescue Timeout::Error => e
    puts "ajax timeout error: #{e.inspect}"
  end
end

def finished_all_ajax_requests?
  page.evaluate_script('jQuery.active').zero?
end

def wait_for_background_job
  begin
    Timeout.timeout(Capybara.default_wait_time) do
      loop until  finished_background_job_request? && finished_all_ajax_requests?
    end
  rescue Timeout::Error => e
    puts 'background job timeout error'
    puts "first(:xpath, \"//div[@id='background_job_modal']\") #{first(:xpath, "//div[@id='background_job_modal']").inspect}, first(:xpath, \"//div[@id='background_job_modal']\") #{first(:xpath, "//div[@id='background_job_modal:visible']").inspect}"
    puts "e: #{e.inspect}"
  end
end

def finished_background_job_request?
  page.evaluate_script("jQuery.find('#background_job_modal:visible').length").zero?
end

Then(/^waiting for ajax to complete$/) do
  puts 'waiting for ajax to complete '
  wait_for_ajax
  puts 'done ajax'
end

Then(/^waiting for background job to complete$/) do
  puts 'waiting for background job to complete'
  wait_for_background_job
  puts 'done background job'
end