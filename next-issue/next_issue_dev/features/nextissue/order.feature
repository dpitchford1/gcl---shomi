@javascript
Feature: Order product
  In order to gain access to the product
  As registered user
  I want to order the product

Background:
  Given I am using the tags "javascript"
  And I have not logged in

Scenario: Create new order
  When  I sign in
  And I go to the payment page
  And I submit the payment form
  Then I should see the error message "Credit card number is required"

Scenario: Create new order with new user
  When I go to the register page
  And I fill in the new profile form with a new user
  And I fill in the credit card form
  And I submit the order
  And I wait for 60 seconds
  Then I should see the notice "Order was successfully created."

Scenario: Existing upgrading to premium
  When  I sign in with
    | email         | password  |
    | prem@t.com    | rogers123 |
  And I wait for 30 seconds
  And I try to upgrade and confirm
  And I wait for 60 seconds
  And I reload the page
  Then I should see the notice "Upgraded to premium"

Scenario: Existing downgrading to basic
  When  I sign in with
    | email         | password  |
    | prem@t.com    | rogers123 |
  And I wait for 30 seconds
  And I try to downgrade and confirm
  And I wait for 60 seconds
  And I reload the page
  Then I should see the notice "Downgraded to basic"

