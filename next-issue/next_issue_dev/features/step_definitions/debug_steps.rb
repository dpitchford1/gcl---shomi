Given /^I wait for (\d+) (second|minute|hour)s?$/ do |n, unit|
  sleep(eval("#{n.to_i}.#{unit}"))
end

Then(/^screenshot$/) do
  Capybara::Screenshot.screenshot_and_save_page
end

When /^I reload the page$/ do
  visit(current_path)
end