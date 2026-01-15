FactoryBot.define do
  factory :client do
    tenant { nil }
    code { "MyString" }
    name { "MyString" }
    name_kana { "MyString" }
    postal_code { "MyString" }
    address { "MyText" }
    phone { "MyString" }
    contact_name { "MyString" }
    contact_email { "MyString" }
    payment_terms { "MyString" }
    notes { "MyText" }
  end
end
