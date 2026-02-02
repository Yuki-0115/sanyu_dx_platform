# frozen_string_literal: true

FactoryBot.define do
  factory :employee do
    sequence(:email) { |n| "employee#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    sequence(:name) { |n| "社員 #{n}" }
    name_kana { "シャイン" }
    phone { "090-1234-5678" }
    employment_type { "regular" }
    role { "worker" }
    hire_date { Date.current - 1.year }

    trait :admin do
      role { "admin" }
    end

    trait :management do
      role { "management" }
    end

    trait :accounting do
      role { "accounting" }
    end

    trait :construction do
      role { "construction" }
    end

    trait :temporary do
      employment_type { "temporary" }
      association :partner
    end
  end
end
