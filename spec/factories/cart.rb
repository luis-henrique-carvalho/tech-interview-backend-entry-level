FactoryBot.define do
  factory :cart do
    total_price { 0.0 }
    session_id { "session_#{SecureRandom.hex(4)}" }
    abandoned_at { nil }
  end
end
