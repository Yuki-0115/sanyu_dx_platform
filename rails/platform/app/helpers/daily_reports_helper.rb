# frozen_string_literal: true

module DailyReportsHelper
  STATUS_LABELS = {
    "draft" => "下書き",
    "confirmed" => "確定済",
    "revised" => "修正済"
  }.freeze

  STATUS_CLASSES = {
    "draft" => "bg-yellow-100 text-yellow-800",
    "confirmed" => "bg-green-100 text-green-800",
    "revised" => "bg-blue-100 text-blue-800"
  }.freeze

  def daily_report_status_label(status)
    STATUS_LABELS[status] || status
  end

  def daily_report_status_class(status)
    STATUS_CLASSES[status] || "bg-gray-100 text-gray-800"
  end

  # 経費ヘルパー
  EXPENSE_TYPE_LABELS = {
    "site" => "現場経費",
    "sales" => "営業経費",
    "admin" => "管理経費"
  }.freeze

  EXPENSE_CATEGORY_LABELS = {
    "material" => "材料費",
    "transport" => "交通費",
    "equipment" => "設備費",
    "rental" => "リース費",
    "consumable" => "消耗品",
    "meal" => "食事代",
    "other" => "その他"
  }.freeze

  EXPENSE_PAYMENT_METHOD_LABELS = {
    "cash" => "現金",
    "company_card" => "会社カード",
    "advance" => "立替",
    "credit" => "掛け"
  }.freeze

  def expense_type_label(type)
    EXPENSE_TYPE_LABELS[type] || type
  end

  def expense_category_label(category)
    EXPENSE_CATEGORY_LABELS[category] || category
  end

  def expense_payment_method_label(method)
    EXPENSE_PAYMENT_METHOD_LABELS[method] || method
  end
end
