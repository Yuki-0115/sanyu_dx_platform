FactoryBot.define do
  factory :project do
    tenant { nil }
    client { nil }
    code { "MyString" }
    name { "MyString" }
    site_address { "MyText" }
    site_lat { "9.99" }
    site_lng { "9.99" }
    has_contract { false }
    has_order { false }
    has_payment_terms { false }
    has_customer_approval { false }
    four_point_completed_at { "2026-01-15 13:29:31" }
    pre_construction_check { "" }
    pre_construction_approved_at { "2026-01-15 13:29:31" }
    estimated_amount { "9.99" }
    order_amount { "9.99" }
    budget_amount { "9.99" }
    actual_cost { "9.99" }
    status { "MyString" }
    sales_user_id { 1 }
    engineering_user_id { 1 }
    construction_user_id { 1 }
    drive_folder_url { "MyText" }
  end
end
