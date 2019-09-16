FactoryGirl.define do
  factory :order do
    offer_id 42
    first_name 'john'
    last_name 'doe'
    billing_option 'test'
    phone_number '555-555-5555'
    tos '1'
  end

  factory :user_order do
    offer_id 'abc123'
    existing_offer_type 'Basic'
    order_id 'abc-order-123'
    full_name 'john doe'
    billing_option 'test'
    billing_account ''
    billing_amount '1'
    status 'New'
    activation_date 'Wed Jun 17 07:00:00 GMT 2015'
  end
end