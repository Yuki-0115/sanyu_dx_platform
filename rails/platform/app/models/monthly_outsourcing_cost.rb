# frozen_string_literal: true

# 月次外注費確定
# 協力会社からの請求書ベースで確定した外注費を管理
class MonthlyOutsourcingCost < ApplicationRecord
  belongs_to :partner
  belongs_to :project
  has_one :cash_flow_entry, as: :source, dependent: :destroy

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :partner_id, uniqueness: { scope: [:year, :month, :project_id],
                                       message: "この協力会社・案件の外注費は既に登録されています" }

  # Callbacks
  after_save :create_or_update_cash_flow_entry

  scope :for_month, ->(year, month) { where(year: year, month: month) }
  scope :for_partner, ->(partner_id) { where(partner_id: partner_id) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }

  def period_label
    "#{year}年#{month}月"
  end

  # === クラスメソッド ===

  # 指定月のデータが存在するか（確定済みとみなす）
  def self.confirmed_for_month?(year, month)
    for_month(year, month).exists?
  end

  # 指定月の合計金額
  def self.total_for_month(year, month)
    for_month(year, month).sum(:amount).to_i
  end

  # 指定月の協力会社別合計
  def self.by_partner_for_month(year, month)
    for_month(year, month)
      .joins(:partner)
      .group("partners.id", "partners.name")
      .sum(:amount)
      .transform_keys { |k| { id: k[0], name: k[1] } }
  end

  # 指定月の協力会社別合計（シンプル版）
  def self.totals_by_partner_for_month(year, month)
    for_month(year, month)
      .joins(:partner)
      .group("partners.name")
      .order("partners.name")
      .sum(:amount)
  end

  private

  def create_or_update_cash_flow_entry
    return if amount.to_d.zero?

    # 外注費の基準日は月末（締め日）
    base_date = Date.new(year, month, 1).end_of_month
    term = partner&.default_payment_term

    # 支払日計算（協力会社の支払サイトがあれば使用、なければ翌月末）
    # 外注費は土日祝日の前営業日に調整
    expected_date = if term
                      term.calculate_payment_date(base_date, adjust_for: :expense)
                    else
                      PaymentTerm.previous_business_day(base_date + 1.month)
                    end

    entry = cash_flow_entry || build_cash_flow_entry
    entry.update!(
      entry_type: "expense",
      category: "outsourcing",
      partner: partner,
      project: project,
      base_date: base_date,
      expected_date: expected_date,
      expected_amount: amount
    )
  end
end
