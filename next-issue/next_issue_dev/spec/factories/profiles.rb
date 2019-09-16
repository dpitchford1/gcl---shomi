FactoryGirl.define do
  factory :profile do
    username 'testuser42@test.com'
    email_address 'testuser42@test.com'
    password 'test1234'
    password_confirmation 'test1234'
    tos '1'
    lang_pref 'en'
    question 1
    answer 'question answer'
  end
end