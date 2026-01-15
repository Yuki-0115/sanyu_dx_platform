FactoryBot.define do
  factory :partner do
    tenant { nil }
    code { "MyString" }
    name { "MyString" }
    has_temporary_employees { false }
    offset_rule { "MyString" }
    closing_day { 1 }
    carryover_balance { "9.99" }
  end
end
