FactoryGirl.define do
  factory :promo_code do
    code 'testcode1234'
    code_type 'test'
    valid_for_product 'nextissue'
    valid_offers ['basic', 'premium']

    trait :discount do
      code_type 'discount'
    end
    trait :redemption do
      code_type 'termsubscription'
    end
    trait :free_trial do
      code_type 'extendedtrial'
    end
    trait :consumer do
      code_type 'consumer'
    end
    trait :business do
      code_type 'business'
    end
    trait :moveextn do
      code_type 'moveextn'
    end
    trait :expired do
      code_type 'expired'
    end
    trait :invalid do
      code_type 'invalid'
    end

    factory :discount_code,    traits: [:discount]
    factory :redemption_code,    traits: [:redemption]
    factory :free_trial_code,    traits: [:free_trial]
    factory :consumer_code,    traits: [:consumer]
    factory :business_code,    traits: [:business]
    factory :moveextn_code,    traits: [:moveextn]
    factory :expired_code, traits: [:expired]
    factory :invalid_code, traits: [:invalid]
  end
end