FactoryBot.define do
  factory :daily_report do
    tenant { nil }
    project { nil }
    foreman { nil }
    report_date { "2026-01-15" }
    weather { "MyString" }
    temperature_high { 1 }
    temperature_low { 1 }
    work_content { "MyText" }
    notes { "MyText" }
    status { "MyString" }
    confirmed_at { "2026-01-15 13:34:58" }
  end
end
