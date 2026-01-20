# frozen_string_literal: true

class Expense < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  EXPENSE_TYPES = %w[site sales admin].freeze
  CATEGORIES = %w[material transport equipment rental consumable meal fuel highway_toll other].freeze
  CATEGORY_LABELS = {
    "material" => "材料費",
    "transport" => "運搬費",
    "equipment" => "機材費",
    "rental" => "リース・レンタル",
    "consumable" => "消耗品",
    "meal" => "飲食費",
    "fuel" => "燃料費",
    "highway_toll" => "高速代",
    "other" => "その他"
  }.freeze
  PAYMENT_METHODS = %w[cash company_card advance credit gas_card etc_card].freeze
  PAYMENT_METHOD_LABELS = {
    "cash" => "現金",
    "company_card" => "会社カード",
    "advance" => "立替",
    "credit" => "掛け",
    "gas_card" => "ガソリンカード",
    "etc_card" => "ETCカード"
  }.freeze
  STATUSES = %w[pending approved rejected].freeze

  # 単位の定義
  UNITS = {
    "fuel" => "L",
    "highway_toll" => "回"
  }.freeze

  # Associations
  belongs_to :daily_report, optional: true
  belongs_to :project, optional: true
  belongs_to :payer, class_name: "Employee", optional: true
  belongs_to :approved_by, class_name: "Employee", optional: true
  belongs_to :confirmed_by, class_name: "Employee", optional: true

  # 領収書・伝票添付
  has_one_attached :receipt
  has_one_attached :voucher

  # Validations
  validates :expense_type, presence: true, inclusion: { in: EXPENSE_TYPES }
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }
  validates :quantity, numericality: { greater_than: 0 }, allow_blank: true

  # Defaults
  attribute :status, :string, default: "pending"
  attribute :is_provisional, :boolean, default: false

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :site_expenses, -> { where(expense_type: "site") }
  scope :provisional, -> { where(is_provisional: true) }
  scope :confirmed, -> { where(is_provisional: false).or(where.not(confirmed_at: nil)) }
  scope :unconfirmed, -> { where(is_provisional: true, confirmed_at: nil) }
  scope :fuel_expenses, -> { where(category: "fuel") }
  scope :highway_expenses, -> { where(category: "highway_toll") }

  # Callbacks
  before_save :set_default_payment_method_for_card_expenses
  before_save :store_provisional_amount, if: :becoming_provisional?

  # Instance methods
  def approve!(user)
    update!(status: "approved", approved_by: user, approved_at: Time.current)
  end

  def reject!(user)
    update!(status: "rejected", approved_by: user, approved_at: Time.current)
  end

  # 仮経費を確定する
  def confirm!(user, confirmed_amount)
    update!(
      is_provisional: false,
      confirmed_at: Time.current,
      confirmed_by: user,
      amount: confirmed_amount
    )
  end

  # カテゴリラベル
  def category_label
    CATEGORY_LABELS[category] || category
  end

  # 支払方法ラベル
  def payment_method_label
    PAYMENT_METHOD_LABELS[payment_method] || payment_method
  end

  # 数量表示（単位付き）
  def quantity_with_unit
    return "-" if quantity.blank?

    unit_str = unit.presence || UNITS[category] || "個"
    "#{quantity}#{unit_str}"
  end

  # 仮経費かどうか
  def provisional?
    is_provisional? && confirmed_at.blank?
  end

  # 確定済みかどうか
  def confirmed?
    !is_provisional? || confirmed_at.present?
  end

  # 燃料費か
  def fuel?
    category == "fuel"
  end

  # 高速代か
  def highway_toll?
    category == "highway_toll"
  end

  # カード精算系か（後日請求書で確定）
  def card_expense?
    fuel? || highway_toll?
  end

  private

  def set_default_payment_method_for_card_expenses
    return unless payment_method.blank?

    self.payment_method = "gas_card" if fuel?
    self.payment_method = "etc_card" if highway_toll?
  end

  def becoming_provisional?
    is_provisional? && is_provisional_changed? && provisional_amount.blank?
  end

  def store_provisional_amount
    self.provisional_amount = amount
  end
end
