FactoryBot.define do
  factory :cart do
    total_price { 0.0 }
    session_id { "session_#{SecureRandom.hex(4)}" }
    last_interaction_at { Time.current }

    trait :abandoned do
      abandoned_at { Time.current }
    end

    trait :with_products do
      after(:create) do |cart|
        create_list(:cart_item, 3, cart: cart)
      end
    end
  end
end
