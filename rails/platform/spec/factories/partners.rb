# frozen_string_literal: true

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "協力会社 #{n}" }
    has_temporary_employees { false }
    carryover_balance { 0 }

    trait :with_temporary_employees do
      has_temporary_employees { true }
    end
  end
end
