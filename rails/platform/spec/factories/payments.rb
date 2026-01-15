FactoryBot.define do
  factory :payment do
    tenant { nil }
    invoice { nil }
    payment_date { "2026-01-15" }
    amount { "9.99" }
    notes { "MyText" }
  end
end
