FactoryBot.define do
  factory :audit_log do
    tenant { nil }
    user { nil }
    auditable_type { "MyString" }
    auditable_id { 1 }
    action { "MyString" }
    changed_data { "" }
  end
end
