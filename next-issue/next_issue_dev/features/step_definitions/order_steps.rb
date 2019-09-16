When(/^I submit the payment form$/) do
  if @tags.include? 'javascript'
    # submit general form with javascript
    within(:xpath, "//form[@id='new_credit_card']") do
      find_button("Place Order").trigger('click')

      step 'waiting for ajax to complete'
      click_button "Place Order"
    end
  else
    # submit form without javascript
    general_form = first(:xpath, "//form[@id='new_credit_card']")
    general_form.all("input[@type='submit']").last.click
  end
  step 'I wait for 2 seconds'
end

When(/^I fill in the credit card form$/) do
  step 'I wait for 4 seconds'
  within(:xpath, "//form[@id='new_credit_card']") do
    fill_in 'field_creditCardNumber', with: '5555555555554444'
    select '12', from: 'field_creditCardExpirationMonth'
    select '2035', from: 'field_creditCardExpirationYear'
    fill_in 'field_cardSecurityCode', with: '123'
    fill_in 'field_creditCardHolderName', with: 'test user'
    fill_in 'field_creditCardAddress1', with: '123 nowhere'
    fill_in 'field_creditCardCity', with: 'Toronto'
    fill_in 'field_creditCardPostalCode', with: 'a0b1c2'
    select 'ON', from: 'field_creditCardState'
    check('tos')
    find_button("Place Order").trigger('click')
    # wait for zuora to return a response
    step 'waiting for background job to complete'
    step 'I wait for 6 seconds'
  end
end

When(/^I submit the order$/) do
  within(:xpath, "//form[@id='new_order']") do
    find_button("Submit Order").trigger('click')
    step 'waiting for background job to complete'
  end
end

When(/^I try to (upgrade|downgrade) and confirm$/) do |context|
  first(:xpath, "//a[@class='btn btn-default change_plan_event']").click
  step 'I wait for 1 seconds'
  find_button("Yes, #{context.to_s.capitalize}").trigger('click')
end