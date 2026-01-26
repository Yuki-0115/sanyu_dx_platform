# frozen_string_literal: true

class Expense < ApplicationRecord
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

  # ========================================
  # 経理処理・会計連携用定数
  # ========================================

  # 経理処理ステータス
  ACCOUNTING_STATUSES = %w[pending_accounting processed].freeze
  ACCOUNTING_STATUS_LABELS = {
    "pending_accounting" => "経理未処理",
    "processed" => "処理済み"
  }.freeze

  # 税区分
  TAX_CATEGORIES = %w[taxable tax_exempt non_taxable].freeze
  TAX_CATEGORY_LABELS = {
    "taxable" => "課税",
    "tax_exempt" => "非課税",
    "non_taxable" => "不課税"
  }.freeze

  # 勘定科目コード（freee/MoneyForward共通）
  # カテゴリから自動マッピング + 経理で変更可能
  ACCOUNT_CODES = {
    # 売上原価系
    "material" => { code: "510", name: "仕入高", freee: "仕入高", moneyforward: "仕入高" },
    "transport" => { code: "513", name: "運搬費", freee: "運搬費", moneyforward: "運搬費" },
    "equipment" => { code: "514", name: "機材費", freee: "消耗品費", moneyforward: "工具器具備品" },
    "rental" => { code: "515", name: "リース料", freee: "リース料", moneyforward: "賃借料" },
    # 販管費系
    "consumable" => { code: "720", name: "消耗品費", freee: "消耗品費", moneyforward: "消耗品費" },
    "meal" => { code: "730", name: "会議費", freee: "会議費", moneyforward: "会議費" },
    "fuel" => { code: "740", name: "車両費", freee: "車両費", moneyforward: "車両費" },
    "highway_toll" => { code: "741", name: "旅費交通費", freee: "旅費交通費", moneyforward: "旅費交通費" },
    "other" => { code: "799", name: "雑費", freee: "雑費", moneyforward: "雑費" }
  }.freeze

  # 勘定科目一覧（手動選択用）
  ACCOUNT_CODE_OPTIONS = [
    { code: "510", name: "仕入高" },
    { code: "513", name: "運搬費" },
    { code: "514", name: "機材費" },
    { code: "515", name: "リース料" },
    { code: "520", name: "外注費" },
    { code: "530", name: "労務費" },
    { code: "720", name: "消耗品費" },
    { code: "721", name: "事務用品費" },
    { code: "730", name: "会議費" },
    { code: "731", name: "交際費" },
    { code: "740", name: "車両費" },
    { code: "741", name: "旅費交通費" },
    { code: "750", name: "通信費" },
    { code: "760", name: "水道光熱費" },
    { code: "799", name: "雑費" }
  ].freeze

  # Associations
  belongs_to :daily_report, optional: true
  belongs_to :project, optional: true
  belongs_to :payer, class_name: "Employee", optional: true
  belongs_to :approved_by, class_name: "Employee", optional: true
  belongs_to :confirmed_by, class_name: "Employee", optional: true
  belongs_to :processed_by, class_name: "Employee", optional: true
  belongs_to :supplier, class_name: "Partner", optional: true

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
  validates :accounting_status, inclusion: { in: ACCOUNTING_STATUSES }, allow_nil: true
  validates :tax_category, inclusion: { in: TAX_CATEGORIES }, allow_nil: true

  # Defaults
  attribute :status, :string, default: "pending"
  attribute :is_provisional, :boolean, default: false
  attribute :accounting_status, :string, default: "pending_accounting"
  attribute :tax_category, :string, default: "taxable"

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :site_expenses, -> { where(expense_type: "site") }
  scope :provisional, -> { where(is_provisional: true) }
  scope :confirmed, -> { where(is_provisional: false).or(where.not(confirmed_at: nil)) }
  scope :unconfirmed, -> { where(is_provisional: true, confirmed_at: nil) }
  scope :fuel_expenses, -> { where(category: "fuel") }
  scope :highway_expenses, -> { where(category: "highway_toll") }

  # 経理処理用スコープ
  scope :pending_accounting, -> { where(accounting_status: "pending_accounting") }
  scope :accounting_processed, -> { where(accounting_status: "processed") }
  scope :ready_for_accounting, -> { approved.pending_accounting }

  # 支払方法別スコープ
  scope :credit_payment, -> { where(payment_method: "credit") }
  scope :card_payment, -> { where(payment_method: %w[company_card gas_card etc_card]) }
  scope :cash_payment, -> { where(payment_method: %w[cash advance]) }

  # 精算用スコープ
  scope :needs_reimbursement, -> { where(reimbursement_required: true, reimbursed: false) }
  scope :reimbursed, -> { where(reimbursed: true) }

  # Callbacks
  before_save :set_default_payment_method_for_card_expenses
  before_save :store_provisional_amount, if: :becoming_provisional?
  before_save :set_default_account_code, if: :should_set_account_code?
  before_save :set_reimbursement_required, if: :payment_method_changed?

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

  # ========================================
  # 経理処理・会計連携メソッド
  # ========================================

  # 経理処理を実行
  def process_accounting!(user, params = {})
    update!(
      accounting_status: "processed",
      processed_by: user,
      processed_at: Time.current,
      account_code: params[:account_code] || account_code || default_account_code,
      tax_category: params[:tax_category] || tax_category,
      accounting_note: params[:accounting_note]
    )
  end

  # 経理処理ステータスラベル
  def accounting_status_label
    ACCOUNTING_STATUS_LABELS[accounting_status] || accounting_status
  end

  # 税区分ラベル
  def tax_category_label
    TAX_CATEGORY_LABELS[tax_category] || tax_category
  end

  # 勘定科目名
  def account_code_name
    if account_code.present?
      option = ACCOUNT_CODE_OPTIONS.find { |o| o[:code] == account_code }
      option ? "#{option[:code]} #{option[:name]}" : account_code
    else
      mapping = ACCOUNT_CODES[category]
      mapping ? "#{mapping[:code]} #{mapping[:name]}" : "-"
    end
  end

  # デフォルトの勘定科目コード
  def default_account_code
    ACCOUNT_CODES.dig(category, :code)
  end

  # freee用の勘定科目名
  def freee_account_name
    ACCOUNT_CODES.dig(category, :freee) || "雑費"
  end

  # MoneyForward用の勘定科目名
  def moneyforward_account_name
    ACCOUNT_CODES.dig(category, :moneyforward) || "雑費"
  end

  # 経理処理待ちか
  def pending_accounting?
    accounting_status == "pending_accounting"
  end

  # 経理処理済みか
  def accounting_processed?
    accounting_status == "processed"
  end

  # 経理処理可能か（承認済みかつ経理未処理）
  def ready_for_accounting?
    approved? && pending_accounting?
  end

  # 承認済みか
  def approved?
    status == "approved"
  end

  # 申請中（未承認）か
  def pending?
    status == "pending"
  end

  # 却下されたか
  def rejected?
    status == "rejected"
  end

  # レシート添付済みか
  def receipt_attached?
    receipt.attached?
  end

  # 伝票添付済みか
  def voucher_attached?
    voucher.attached?
  end

  # 掛け払いか
  def credit_payment?
    payment_method == "credit"
  end

  # カード払いか
  def card_payment?
    %w[company_card gas_card etc_card].include?(payment_method)
  end

  # 現金・立替払いか
  def cash_payment?
    %w[cash advance].include?(payment_method)
  end

  # 立替払いか
  def advance_payment?
    payment_method == "advance"
  end

  # 精算が必要か
  def needs_reimbursement?
    reimbursement_required? && !reimbursed?
  end

  # 精算処理
  def reimburse!
    update!(reimbursed: true, reimbursed_at: Time.current)
  end

  # 会計ソフト連携用のエクスポートデータ
  def to_accounting_export
    {
      date: daily_report&.report_date || created_at.to_date,
      account_code: account_code || default_account_code,
      account_name: account_code_name,
      amount: amount.to_i,
      tax_category: tax_category,
      description: "#{project&.name} #{description}".strip,
      payment_method: payment_method,
      project_code: project&.code,
      receipt_attached: receipt_attached?
    }
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

  def should_set_account_code?
    account_code.blank? && category.present?
  end

  def set_default_account_code
    self.account_code = default_account_code
  end

  # 立替払いは精算必要フラグを立てる
  def set_reimbursement_required
    if payment_method.in?(%w[advance cash])
      self.reimbursement_required = true
    else
      self.reimbursement_required = false
    end
  end
end
