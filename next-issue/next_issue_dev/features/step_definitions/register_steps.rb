Given(/^I am using the tags "(.*?)"$/) do |tags|
  @tags = tags
end

When(/^I go to the (.*?) page$/) do |page_path|
  if page_path == 'payment'
    visit '/orders/new'
  else
    visit "/#{page_path}"
  end
  step 'I wait for 2 seconds'
end

When(/^I submit the general form$/) do
  if @tags.include? 'javascript'
    # submit general form with javascript
    within(:xpath, "//form[@id='new_profile']") do
      find_button("Sign Up").trigger('click')

      step 'waiting for ajax to complete'
      click_button "Sign Up"
    end
  else
    # submit general form without javascript
    general_form = first(:xpath, "//form[@class='simple_form general-form']")
    general_form.find("input[@type='submit']").click
  end
end

Then(/^I should see the new profile form$/) do
  new_profile_form = page.find(:xpath, "//form[@id='new_profile']")
  new_profile_form.should have_no_selector(:xpath, ".//input[@id='this_id_does_not_exist']")

  expect(new_profile_form).to have_xpath(".//input[@id='profile_email_address']")
end

Then(/^I should see general form errors$/) do
  general_form = find(:xpath, "//form[@class='simple_form general-form']")
  expect(general_form).to have_css("p.help-inline")
end

Then(/^I should see the error message "(.*?)"$/) do |error_message|
  step 'I wait for 4 seconds'
  if @tags.include? 'javascript'
    # with javascript tags, the all/first xpath returns []/nil
    expect(all("p.help-inline").map(&:text)).to include error_message
  else
    # without javascript tag, both css & xpath return results
    expect(all(:xpath, "//p[@class='help-inline']").map(&:text)).to include error_message
  end
end


When(/^I fill in the new profile form with an? (existing|new) user$/) do |user_type|
  email_address = if user_type == 'new'
                    Digest::SHA1.hexdigest(Time.now.to_i.to_s) + '@demo.com'
                  else
                    'demo@demo.com'
                  end

  puts "email_address used '#{email_address}'"
  within(:xpath, "//form[@id='new_profile']") do
    fill_in 'profile[email_address]', with: email_address
    fill_in 'profile[email_address_confirmation]', with: email_address
    fill_in 'profile[password]', with: 'rogers123'
    fill_in 'profile[password_confirmation]', with: 'rogers123'
    fill_in 'profile[answer]', with: 'test answer'
    select "What is your mother's maiden name?", from: 'profile[question]'

    find_button("Sign Up").trigger('click')
    step 'waiting for background job to complete'
    step 'I wait for 6 seconds' if user_type == 'new'
  end
  step 'I wait for 10 seconds'
end


Then(/^I should see "(.*?)" on the page$/) do |text|
  step 'I wait for 4 seconds'
  expect(page.has_text?(text)).to eql true
end

Then(/^I should see the sign in form$/) do
  new_session_form = page.find(:xpath, "//form[@id='new_session']")

  expect(new_session_form).to have_xpath(".//input[@id='session_username']")
end

Then(/^I should see the (notice|error) "(.*?)"$/) do |msg_type, message|
  step 'I wait for 4 seconds'

  alert_div = if @tags.include? 'javascript'
                first("div##{msg_type}_div_id")
              else
                first(:xpath, "//div[@id='#{msg_type}_div_id']")
              end

  expect(alert_div).to_not be_nil
  expect(alert_div.visible?).to eql true
  expect(alert_div.text).to eql message
end
