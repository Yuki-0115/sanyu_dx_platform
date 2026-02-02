# frozen_string_literal: true

FactoryBot.define do
  factory :client do
    sequence(:name) { |n| "顧客企業 #{n}" }
    name_kana { "コキャクキギョウ" }
    postal_code { "812-0001" }
    address { "福岡県福岡市博多区" }
    phone { "092-123-4567" }
    contact_name { "担当太郎" }
    contact_email { "tantou@example.com" }
    payment_terms { "月末締め翌月末払い" }
  end
end
