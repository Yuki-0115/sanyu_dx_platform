FactoryBot.define do
  factory :expense do
    tenant { nil }
    daily_report { nil }
    project { nil }
    expense_type { "MyString" }
    category { "MyString" }
    description { "MyText" }
    amount { "9.99" }
    payer { nil }
    payment_method { "MyString" }
    status { "MyString" }
    approved_by_id { 1 }
    approved_at { "2026-01-15 13:35:14" }
  end
end
