Feature: Register New Account
  In order to create a new account
  As a guest
  I want to create an account

Scenario: Submit empty new profile form
  Given I am using the tags ""
  And I have not logged in
  When I go to the register page
  And I submit the general form
  Then I should see the new profile form
  And I should see general form errors
  And I should see the error message "Please enter an email address."

@javascript
Scenario: Create existing profile
  Given I am using the tags "javascript"
  And  I have not logged in
  When I go to the register page
  And I fill in the new profile form with an existing user
  Then I should see "This is an existing myRogers profile or an existing Next Issue profile" on the page
  And I should see the sign in form

@javascript
Scenario: Login with demo@demo.com
  Given I am using the tags "javascript"
  When  I sign in with
    | email         | password  |
    | demo@demo.com | rogers123 |
  Then I should see the notice "Successfully logged in."

@javascript
Scenario: Redirect register page when logged
  Given I am using the tags "javascript"
  When  I sign in
  And I go to the signin page
  Then I should see the notice "Already logged in!"

# order.feature has a create new user & new order which will test registering new user
## Only run this to test the profile creation
#@javascript @ignore
#Scenario: Create new user
#  Given I am using the tags "javascript"
#  And  I have not logged in
#  When I go to the register page
#  And I fill in the new profile form with a new user
#  Then I should see the notice "Congratulations. You have created a Next Issue Account. Continue with your purchase"