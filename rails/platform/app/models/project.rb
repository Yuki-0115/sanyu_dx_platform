# frozen_string_literal: true

class Project < ApplicationRecord
  include Auditable

  # Constants
  STATUSES = %w[draft estimating ordered preparing in_progress completed invoiced paid closed].freeze
  PROJECT_TYPES = %w[regular misc].freeze
  PROJECT_TYPE_LABELS = {
    "regular" => "通常案件",
    "misc" => "その他（小工事・常用）"
  }.freeze

  # 受注フロー種別
  ORDER_FLOWS = %w[standard oral_first].freeze
  ORDER_FLOW_LABELS = {
    "standard" => "通常（見積→注文書→受注）",
    "oral_first" => "口頭先行（口頭受注→後から注文書）"
  }.freeze

  # Associations
  belongs_to :client, optional: true
  belongs_to :sales_user, class_name: "Employee", optional: true
  belongs_to :engineering_user, class_name: "Employee", optional: true
  belongs_to :construction_user, class_name: "Employee", optional: true

  has_one :budget, dependent: :destroy
  has_many :estimates, dependent: :destroy
  has_many :daily_reports, dependent: :restrict_with_error
  has_many :expenses, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  has_many :project_assignments, dependent: :destroy
  has_many :assigned_employees, through: :project_assignments, source: :employee
  has_many :safety_folders, dependent: :nullify
  has_many :project_documents, dependent: :destroy

  # Validations
  validates :code, uniqueness: true
  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :project_type, inclusion: { in: PROJECT_TYPES }
  validates :order_flow, inclusion: { in: ORDER_FLOWS }

  # Callbacks
  before_validation :generate_code, on: :create

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :project_type, :string, default: "regular"
  attribute :order_flow, :string, default: "standard"
  attribute :has_contract, :boolean, default: false
  attribute :has_order, :boolean, default: false
  attribute :has_payment_terms, :boolean, default: false
  attribute :has_customer_approval, :boolean, default: false

  # Scopes
  scope :active, -> { where.not(status: %w[closed paid]) }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :regular, -> { where(project_type: "regular") }
  scope :misc, -> { where(project_type: "misc") }

  # Instance methods
  def misc?
    project_type == "misc"
  end

  def regular?
    project_type == "regular"
  end

  def standard_flow?
    order_flow == "standard"
  end

  def oral_first_flow?
    order_flow == "oral_first"
  end

  # 口頭受注を記録
  def record_oral_order!(amount:, note: nil)
    update!(
      oral_order_amount: amount,
      oral_order_received_at: Time.current,
      oral_order_note: note,
      order_amount: amount # 受注金額にも反映
    )
  end

  # 後から注文書を受領
  def receive_order_document!
    update!(
      order_document_received_at: Time.current,
      has_order: true
    )
  end

  # 注文書が未受領かどうか（口頭先行フローで使用）
  def order_document_pending?
    oral_first_flow? && oral_order_received_at.present? && order_document_received_at.blank?
  end

  def four_point_completed?
    has_contract && has_order && has_payment_terms && has_customer_approval
  end

  def complete_four_point_check!
    return false unless four_point_completed?

    update!(four_point_completed_at: Time.current, status: "ordered")
  end

  # 着工前ゲート（5点チェック）
  def pre_construction_gate_completed?
    site_conditions_checked && night_work_checked && regulations_checked &&
      safety_docs_checked && delivery_checked
  end

  def complete_pre_construction_gate!
    return false unless pre_construction_gate_completed?

    update!(pre_construction_gate_completed_at: Time.current, status: "preparing")
  end

  # 着工開始
  def start_construction!
    return false unless status == "preparing"

    update!(status: "in_progress")
  end

  # 実績原価（日報から動的計算）
  def calculated_actual_cost
    daily_reports.where(status: %w[confirmed revised]).sum do |report|
      report.total_cost
    end
  end

  # actual_cost は DB の値があればそれを使い、なければ計算
  def actual_cost
    read_attribute(:actual_cost) || calculated_actual_cost
  end

  # Profit margin calculation
  def profit_margin
    return nil unless order_amount && order_amount.positive?

    cost = actual_cost
    return nil unless cost && cost.positive?

    ((order_amount - cost) / order_amount * 100).round(2)
  end

  # 粗利額
  def gross_profit
    return nil unless order_amount

    order_amount - (actual_cost || 0)
  end

  # ========================================
  # 現場台帳（第3層）用の集計メソッド
  # ========================================

  # 人工単価（社員区分別、実行予算から取得、未設定時はデフォルト18,000円）
  def regular_labor_unit_price
    budget&.regular_labor_unit_price || 18_000
  end

  def temporary_labor_unit_price
    budget&.temporary_labor_unit_price || 18_000
  end

  def outsourcing_unit_price
    budget&.outsourcing_unit_price || 18_000
  end

  # 確定済み日報を取得
  def confirmed_daily_reports
    daily_reports.where(status: %w[confirmed revised])
  end

  # 正社員の人工数
  def site_ledger_regular_man_days
    confirmed_daily_reports
      .joins(attendances: :employee)
      .where(employees: { employment_type: "regular" })
      .sum("
        CASE attendances.attendance_type
          WHEN 'full' THEN 1
          WHEN 'half' THEN 0.5
          ELSE 0
        END
      ").to_d
  end

  # 仮社員の人工数
  def site_ledger_temporary_man_days
    confirmed_daily_reports
      .joins(attendances: :employee)
      .where(employees: { employment_type: "temporary" })
      .sum("
        CASE attendances.attendance_type
          WHEN 'full' THEN 1
          WHEN 'half' THEN 0.5
          ELSE 0
        END
      ").to_d
  end

  # 外部（協力会社）の人工数（出面でemployeeがnilまたはexternal）
  def site_ledger_external_man_days
    # employee_idがnilの出面（外部要員として入力されたもの）
    nil_employee_days = confirmed_daily_reports
      .joins(:attendances)
      .where(attendances: { employee_id: nil })
      .sum("
        CASE attendances.attendance_type
          WHEN 'full' THEN 1
          WHEN 'half' THEN 0.5
          ELSE 0
        END
      ").to_d

    # externalタイプの社員の出面
    external_days = confirmed_daily_reports
      .joins(attendances: :employee)
      .where(employees: { employment_type: "external" })
      .sum("
        CASE attendances.attendance_type
          WHEN 'full' THEN 1
          WHEN 'half' THEN 0.5
          ELSE 0
        END
      ").to_d

    nil_employee_days + external_days
  end

  # 外注エントリの人工数（OutsourcingEntry）
  def site_ledger_outsourcing_man_days
    confirmed_daily_reports.joins(:outsourcing_entries).sum("
      CASE outsourcing_entries.attendance_type
        WHEN 'full' THEN outsourcing_entries.headcount
        WHEN 'half' THEN outsourcing_entries.headcount * 0.5
        ELSE 0
      END
    ").to_d
  end

  # 総人工数（全区分合計）
  def site_ledger_total_man_days
    site_ledger_regular_man_days + site_ledger_temporary_man_days + site_ledger_external_man_days
  end

  # 現場台帳：正社員労務費
  def site_ledger_regular_labor_cost
    (regular_labor_unit_price * site_ledger_regular_man_days).round(0)
  end

  # 現場台帳：仮社員労務費
  def site_ledger_temporary_labor_cost
    (temporary_labor_unit_price * site_ledger_temporary_man_days).round(0)
  end

  # 現場台帳：外部労務費
  def site_ledger_external_labor_cost
    (outsourcing_unit_price * site_ledger_external_man_days).round(0)
  end

  # 現場台帳：労務費合計
  def site_ledger_labor_cost
    site_ledger_regular_labor_cost + site_ledger_temporary_labor_cost + site_ledger_external_labor_cost
  end

  # 現場台帳：外注費（外注エントリ × 外注単価）
  def site_ledger_outsourcing_cost
    (outsourcing_unit_price * site_ledger_outsourcing_man_days).round(0)
  end

  # 現場台帳：材料費（経費の material カテゴリ合計）
  def site_ledger_material_cost
    site_ledger_expenses_by_category["material"] || 0
  end

  # 現場台帳：その他経費（material以外の経費合計）
  def site_ledger_expense_cost
    total = 0
    site_ledger_expenses_by_category.each do |category, amount|
      total += amount unless category == "material"
    end
    total
  end

  # 経費をカテゴリ別に集計
  def site_ledger_expenses_by_category
    @site_ledger_expenses_by_category ||= begin
      result = Hash.new(0)

      # 日報に紐づく経費（承認済み）
      Expense.where(daily_report_id: confirmed_daily_reports.select(:id))
             .where(status: "approved")
             .group(:category)
             .sum(:amount)
             .each { |cat, amt| result[cat] += amt.to_i }

      # 案件に直接紐づく経費（承認済み）
      expenses.where(status: "approved")
              .group(:category)
              .sum(:amount)
              .each { |cat, amt| result[cat] += amt.to_i }

      result
    end
  end

  # 現場台帳：原価合計
  def site_ledger_total_cost
    site_ledger_labor_cost + site_ledger_outsourcing_cost +
      site_ledger_material_cost + site_ledger_expense_cost
  end

  # 現場台帳：粗利（受注金額 - 原価合計）
  def site_ledger_gross_profit
    return nil unless order_amount

    order_amount - site_ledger_total_cost
  end

  # 現場台帳：利益率
  def site_ledger_profit_rate
    return nil unless order_amount && order_amount.positive?

    ((site_ledger_gross_profit.to_d / order_amount) * 100).round(1)
  end

  # 現場台帳：予算との差異
  def site_ledger_budget_variance
    return {} unless budget

    {
      labor: (budget.labor_cost || 0) - site_ledger_labor_cost,
      outsourcing: (budget.outsourcing_cost || 0) - site_ledger_outsourcing_cost,
      material: (budget.material_cost || 0) - site_ledger_material_cost,
      expense: (budget.expense_cost || 0) - site_ledger_expense_cost,
      total: (budget.total_cost || 0) - site_ledger_total_cost
    }
  end

  private

  def generate_code
    return if code.present?

    prefix = "PJ"
    date_part = Date.current.strftime("%Y%m")
    seq = Project.where("code LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.code = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end
end
