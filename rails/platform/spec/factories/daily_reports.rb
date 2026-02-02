# frozen_string_literal: true

FactoryBot.define do
  factory :daily_report do
    association :project
    association :foreman, factory: :employee
    report_date { Date.current }
    weather { "sunny" }
    work_content { "テスト作業内容" }
    status { "draft" }

    trait :confirmed do
      status { "confirmed" }
      confirmed_at { Time.current }
    end

    trait :external do
      project { nil }
      is_external { true }
      external_site_name { "外部現場A" }
    end
  end
end
