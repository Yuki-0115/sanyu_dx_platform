# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    association :client
    sequence(:name) { |n| "テスト工事案件 #{n}" }
    site_address { "福岡県大野城市" }
    status { "draft" }
    project_type { "regular" }
    order_flow { "standard" }

    trait :ordered do
      status { "ordered" }
      has_contract { true }
      has_order { true }
      has_payment_terms { true }
      has_customer_approval { true }
      four_point_completed_at { Time.current }
      order_amount { 1_000_000 }
    end

    trait :in_progress do
      ordered
      status { "in_progress" }
    end

    trait :completed do
      in_progress
      status { "completed" }
      actual_end_date { Date.current }
    end

    trait :misc do
      project_type { "misc" }
    end
  end
end
