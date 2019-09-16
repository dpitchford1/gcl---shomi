Given(/^I have not logged in$/) do
  @current_session = Session.new
  Portal.current_session = @current_session
  @session = @current_session  # For modal sign in
end

When(/^I sign in$/) do
  step "I sign in as \"demo@demo.com\" with \"rogers123\""
end

When(/^I sign in with$/) do |table|
  table.hashes.each do |row|
    step "I sign in as \"#{row[:email]}\" with \"#{row[:password]}\""
  end
  step 'I wait for 10 seconds'
end

When(/^I sign in as "(.*)" with "(.*)"$/) do |email, password|
  visit '/signin'

  within(:xpath, "//form[@id='new_session']") do
    fill_in 'session_username', with: email
    fill_in 'session_password', with: password

    find_button("Sign in").trigger('click')
    step 'waiting for background job to complete'
  end
  step 'I wait for 6 seconds'
end
