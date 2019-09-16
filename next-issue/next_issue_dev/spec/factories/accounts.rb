FactoryGirl.define do
  factory :account do
    account_desc 'test account'
    account_token 'somehash42'
    billing_address_province 'Ontario'
    billing_address_postal_code 'A1B2C3'
  end
end