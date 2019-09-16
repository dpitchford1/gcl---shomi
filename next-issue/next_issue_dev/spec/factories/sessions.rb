FactoryGirl.define do
  factory :session do
    username 'testuser42@test.com'
    email_address 'testuser42@test.com'
    password 'test1234'

    trait :unregistered do
      username nil
      email_address nil
      password nil
    end
  
    factory :unregistered_session,    traits: [:unregistered]
  end
end