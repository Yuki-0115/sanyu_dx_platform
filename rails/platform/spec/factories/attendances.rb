FactoryBot.define do
  factory :attendance do
    tenant { nil }
    daily_report { nil }
    employee { nil }
    attendance_type { "MyString" }
    start_time { "2026-01-15 13:35:13" }
    end_time { "2026-01-15 13:35:13" }
    travel_distance { 1 }
  end
end
