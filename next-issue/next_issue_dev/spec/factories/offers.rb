FactoryGirl.define do
  factory :offer do
    offer_id 'abc123'
    price '1.25'
    frequency 'onetime'
    desc_en 'test offer'
    desc_fr 'fr test offer'
    product_code 'test'
  end
end