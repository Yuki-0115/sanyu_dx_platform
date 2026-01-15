FactoryBot.define do
  factory :budget do
    tenant { nil }
    project { nil }
    target_profit_rate { "9.99" }
    material_cost { "9.99" }
    outsourcing_cost { "9.99" }
    labor_cost { "9.99" }
    expense_cost { "9.99" }
    total_cost { "9.99" }
    notes { "MyText" }
    status { "MyString" }
    confirmed_by_id { 1 }
    confirmed_at { "2026-01-15 13:29:32" }
  end
end
