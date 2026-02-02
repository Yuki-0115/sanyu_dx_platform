# frozen_string_literal: true

class FixedExpenseSchedule < ApplicationRecord
  CATEGORIES = {
    "salary" => "給与",
    "social_insurance" => "社会保険",
    "tax" => "税金",
    "rent" => "家賃",
    "lease" => "リース料",
    "insurance" => "保険",
    "vehicle" => "ガソリン・車両費",
    "phone" => "ドコモ・電話代",
    "utility" => "水道光熱費",
    "card" => "カード",
    "fees" => "手数料",
    "machine_rental" => "機械レンタル・相殺",
    "advisory_fee" => "顧問料",
    "materials" => "材料・現場経費",
    "trainee" => "実習生",
    "loan" => "貸付金",
    "expense" => "経費",
    "miscellaneous" => "雑費"
  }.freeze

  # 支払日タイプ: fixed(固定日)、variable(変動日)
  PAYMENT_TYPES = {
    "fixed" => "固定",
    "variable" => "変動"
  }.freeze

  # Validations
  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES.keys }
  validates :payment_day, presence: true, inclusion: { in: 0..31 }
  validates :payment_type, presence: true, inclusion: { in: PAYMENT_TYPES.keys }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Associations
  has_many :cash_flow_entries, as: :source, dependent: :destroy
  has_many :monthly_amounts, class_name: "FixedExpenseMonthlyAmount", dependent: :destroy

  # Callbacks
  after_save :generate_cash_flow_entries_for_future_months

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_category, ->(cat) { where(category: cat) }

  # Calculate payment date for a given month
  # adjust_for_holiday: true の場合、土日祝日は前営業日に調整
  def payment_date_for_month(year, month, adjust_for_holiday: false)
    base = Date.new(year, month, 1)
    raw_date = if payment_day.zero?
                 base.end_of_month
               else
                 day = [payment_day, base.end_of_month.day].min
                 Date.new(year, month, day)
               end

    if adjust_for_holiday
      PaymentTerm.previous_business_day(raw_date)
    else
      raw_date
    end
  end

  def category_label
    CATEGORIES[category] || category
  end

  def payment_day_label
    payment_day.zero? ? "末日" : "#{payment_day}日"
  end

  # 金額が変動かどうか
  def amount_variable?
    amount_variable
  end

  # 金額が固定かどうか
  def amount_fixed?
    !amount_variable
  end

  def payment_type_label
    PAYMENT_TYPES[payment_type] || payment_type
  end

  def amount_type_label
    amount_variable? ? "変動" : "固定"
  end

  # 指定した年月の金額を取得（月別金額 > デフォルト金額）
  def amount_for_month(year, month)
    if amount_variable?
      # 変動の場合は月別金額を優先、なければデフォルト金額
      monthly_amounts.find_by(year: year, month: month)&.amount || amount || 0
    else
      # 固定の場合はデフォルト金額
      amount || 0
    end
  end

  # 指定した年月の月別金額レコードを取得または作成
  def monthly_amount_for(year, month)
    monthly_amounts.find_or_initialize_by(year: year, month: month)
  end

  # 月別金額の入力状況をチェック（変動金額のみ）
  # 今月の金額が入力されているか
  def current_month_amount_entered?
    return true unless amount_variable?

    current = Date.current
    monthly_amounts.exists?(year: current.year, month: current.month)
  end

  # 翌月の金額が入力されているか
  def next_month_amount_entered?
    return true unless amount_variable?

    next_month = Date.current + 1.month
    monthly_amounts.exists?(year: next_month.year, month: next_month.month)
  end

  # 最後に金額が入力されている年月を取得
  def last_entered_month
    return nil unless amount_variable?

    last_entry = monthly_amounts.order(year: :desc, month: :desc).first
    return nil unless last_entry

    Date.new(last_entry.year, last_entry.month, 1)
  end

  # 最後に入力された年月のラベル
  def last_entered_month_label
    last = last_entered_month
    return "未入力" unless last

    "#{last.year}年#{last.month}月まで"
  end

  # 入力状況のステータス（:ok, :warning, :danger）
  def monthly_amount_status
    return :ok unless amount_variable?

    if !current_month_amount_entered?
      :danger
    elsif !next_month_amount_entered?
      :warning
    else
      :ok
    end
  end

  # 入力状況のメッセージ
  def monthly_amount_status_message
    return nil unless amount_variable?

    case monthly_amount_status
    when :danger
      current = Date.current
      "#{current.year}年#{current.month}月が未入力です"
    when :warning
      next_month = Date.current + 1.month
      "#{next_month.year}年#{next_month.month}月が未入力です"
    else
      nil
    end
  end

  # 指定した年月のCashFlowEntryを生成/更新
  def generate_cash_flow_entry_for(year, month)
    return unless active?

    # 固定費は土日祝日の前営業日に調整
    payment_date = payment_date_for_month(year, month, adjust_for_holiday: true)
    base_date = Date.new(year, month, 1)

    # 金額を取得（変動の場合は月別金額を参照）
    entry_amount = amount_for_month(year, month)

    entry = cash_flow_entries.find_or_initialize_by(base_date: base_date)

    # 手動編集されていない場合のみ更新
    unless entry.manual_override?
      entry.assign_attributes(
        entry_type: "expense",
        category: category,
        expected_date: payment_date,
        expected_amount: entry_amount,
        subcategory: name
      )
      entry.save!
    end
    entry
  end

  private

  # 保存時にエントリを自動生成（今月と翌月）
  def generate_cash_flow_entries_for_future_months
    return unless active?

    current = Date.current
    [current, current + 1.month].each do |date|
      generate_cash_flow_entry_for(date.year, date.month)
    end
  end
end
