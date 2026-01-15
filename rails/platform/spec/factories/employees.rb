FactoryBot.define do
  factory :employee do
    tenant { nil }
    partner { nil }
    code { "MyString" }
    name { "MyString" }
    name_kana { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    employment_type { "MyString" }
    hire_date { "2026-01-15" }
    role { "MyString" }
  end
end
