FactoryBot.define do
  factory :invoice do
    tenant { nil }
    project { nil }
    invoice_number { "MyString" }
    amount { "9.99" }
    tax_amount { "9.99" }
    total_amount { "9.99" }
    issued_date { "2026-01-15" }
    due_date { "2026-01-15" }
    status { "MyString" }
  end
end
