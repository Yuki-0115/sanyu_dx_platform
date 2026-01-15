FactoryBot.define do
  factory :offset do
    tenant { nil }
    partner { nil }
    year_month { "MyString" }
    total_salary { "9.99" }
    social_insurance { "9.99" }
    offset_amount { "9.99" }
    revenue_amount { "9.99" }
    balance { "9.99" }
    status { "MyString" }
    confirmed_by_id { 1 }
    confirmed_at { "2026-01-15 13:35:25" }
  end
end
