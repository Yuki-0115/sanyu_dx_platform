FactoryBot.define do
  factory :estimate_template do
    template_type { "MyString" }
    name { "MyString" }
    content { "MyText" }
    is_shared { false }
    employee { nil }
    sort_order { 1 }
  end
end
