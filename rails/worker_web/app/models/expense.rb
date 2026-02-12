# frozen_string_literal: true

class Expense < ApplicationRecord
  EXPENSE_TYPES = %w[site sales admin].freeze
  CATEGORIES = %w[material transport equipment rental machinery_own machinery_rental consumable meal fuel highway_toll other].freeze
  CATEGORY_LABELS = {
    "material" => "材料費", "transport" => "運搬費", "equipment" => "機材費",
    "rental" => "リース・レンタル", "machinery_own" => "機械(自社)", "machinery_rental" => "機械(レンタル)",
    "consumable" => "消耗品", "meal" => "飲食費", "fuel" => "燃料費", "highway_toll" => "高速代", "other" => "その他"
  }.freeze
  PAYMENT_METHODS = %w[cash company_card advance credit gas_card etc_card].freeze
  PAYMENT_METHOD_LABELS = {
    "cash" => "現金", "company_card" => "会社カード", "advance" => "立替",
    "credit" => "掛け", "gas_card" => "ガソリンカード", "etc_card" => "ETCカード"
  }.freeze

  belongs_to :daily_report, optional: true
  belongs_to :project, optional: true
  belongs_to :payer, class_name: "Worker", foreign_key: :payer_id, optional: true
  belongs_to :supplier, class_name: "Partner", optional: true

  has_one_attached :receipt
  has_one_attached :voucher

  validates :expense_type, presence: true, inclusion: { in: EXPENSE_TYPES }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }, unless: :amount_pending?

  def category_label
    CATEGORY_LABELS[category] || category
  end

  def payment_method_label
    PAYMENT_METHOD_LABELS[payment_method] || payment_method
  end
end
