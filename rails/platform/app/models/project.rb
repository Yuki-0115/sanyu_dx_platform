# frozen_string_literal: true

class Project < ApplicationRecord
  include Auditable

  # Constants
  STATUSES = %w[draft estimating ordered preparing in_progress completed invoiced paid closed].freeze
  PROJECT_TYPES = %w[regular misc].freeze

  # デフォルト人工単価（円/人日）
  DEFAULT_LABOR_UNIT_PRICE = 18_000
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

  # 区分（一次/二次/三次）
  CONTRACT_TIERS = %w[first second third].freeze
  CONTRACT_TIER_LABELS = {
    "first" => "一次",
    "second" => "二次",
    "third" => "三次"
  }.freeze

  # 専任/非専任
  ENGINEER_TYPES = %w[exclusive non_exclusive].freeze
  ENGINEER_TYPE_LABELS = {
    "exclusive" => "専任",
    "non_exclusive" => "非専任"
  }.freeze

  # 安全書類ステータス
  SAFETY_DOC_STATUSES = %w[not_submitted submitted].freeze
  SAFETY_DOC_STATUS_LABELS = {
    "not_submitted" => "未",
    "submitted" => "済"
  }.freeze

  # 安全書類提出方法
  SAFETY_DOC_METHODS = %w[email gs ccus bl gw].freeze
  SAFETY_DOC_METHOD_LABELS = {
    "email" => "メール",
    "gs" => "GS",
    "ccus" => "CCUS",
    "bl" => "BL",
    "gw" => "GW"
  }.freeze

  # Associations
  belongs_to :client, optional: true
  belongs_to :sales_user, class_name: "Employee", optional: true
  belongs_to :engineering_user, class_name: "Employee", optional: true
  belongs_to :construction_user, class_name: "Employee", optional: true
  belongs_to :chief_engineer, class_name: "Employee", optional: true
  belongs_to :site_agent, class_name: "Employee", optional: true
  belongs_to :safety_doc_person, class_name: "Employee", optional: true

  has_one :budget, dependent: :destroy
  has_many :estimates, dependent: :destroy
  has_many :daily_reports, dependent: :restrict_with_error
  has_many :expenses, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  has_many :project_assignments, dependent: :destroy
  has_many :assigned_employees, through: :project_assignments, source: :employee
  has_many :safety_folders, dependent: :nullify
  has_many :safety_files, dependent: :destroy
  has_many :project_safety_requirements, dependent: :destroy
  has_many :required_safety_document_types, through: :project_safety_requirements, source: :safety_document_type
  has_many :project_documents, dependent: :destroy
  has_many :monthly_progresses, class_name: "ProjectMonthlyProgress", dependent: :destroy
  has_many :outsourcing_schedules, dependent: :destroy
  has_many :project_cost_templates, dependent: :destroy
  has_many :project_messages, dependent: :destroy

  # Validations
  validates :code, uniqueness: true
  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :project_type, inclusion: { in: PROJECT_TYPES }
  validates :order_flow, inclusion: { in: ORDER_FLOWS }
  validates :contract_tier, inclusion: { in: CONTRACT_TIERS }
  validates :engineer_type, inclusion: { in: ENGINEER_TYPES }
  validates :safety_doc_status, inclusion: { in: SAFETY_DOC_STATUSES }
  validates :safety_doc_method, inclusion: { in: SAFETY_DOC_METHODS }, allow_blank: true

  # Callbacks
  before_validation :generate_code, on: :create
  after_create_commit :notify_project_created
  after_create_commit :create_drive_folder
  after_update_commit :notify_status_changes

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :project_type, :string, default: "regular"
  attribute :order_flow, :string, default: "standard"
  attribute :has_contract, :boolean, default: false
  attribute :has_order, :boolean, default: false
  attribute :has_payment_terms, :boolean, default: false
  attribute :has_customer_approval, :boolean, default: false
  attribute :contract_tier, :string, default: "first"
  attribute :engineer_type, :string, default: "non_exclusive"
  attribute :safety_doc_status, :string, default: "not_submitted"

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

  # 主要な見積書を取得（承認済み→提出済み→最新の順で優先）
  def estimate
    estimates.order(
      Arel.sql("CASE status WHEN 'approved' THEN 0 WHEN 'submitted' THEN 1 ELSE 2 END"),
      created_at: :desc
    ).first
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

  # 人工単価（社員区分別、実行予算から取得、未設定時はデフォルト単価）
  def regular_labor_unit_price
    budget&.regular_labor_unit_price || DEFAULT_LABOR_UNIT_PRICE
  end

  def temporary_labor_unit_price
    budget&.temporary_labor_unit_price || DEFAULT_LABOR_UNIT_PRICE
  end

  def outsourcing_unit_price
    budget&.outsourcing_unit_price || DEFAULT_LABOR_UNIT_PRICE
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

  # ========================================
  # 労務費（正社員：人工×単価で自動計算）
  # ========================================

  # 現場台帳：労務費（正社員のみ）= 人工数 × 単価
  def site_ledger_labor_cost
    (regular_labor_unit_price * site_ledger_regular_man_days).round(0)
  end

  # ========================================
  # 外注費（人工×単価 + 請負出来高）
  # ========================================

  # 外注エントリの人工数（billing_type = 'man_days' のみ）
  def site_ledger_outsourcing_man_days
    confirmed_daily_reports
      .joins(:outsourcing_entries)
      .where(outsourcing_entries: { billing_type: "man_days" })
      .sum("
        CASE outsourcing_entries.attendance_type
          WHEN 'full' THEN outsourcing_entries.headcount
          WHEN 'half' THEN outsourcing_entries.headcount * 0.5
          ELSE 0
        END
      ").to_d
  end

  # 現場台帳：外注費（人工）= 人工数 × 単価
  def site_ledger_outsourcing_man_days_cost
    (outsourcing_unit_price * site_ledger_outsourcing_man_days).round(0)
  end

  # 現場台帳：外注費（請負出来高）= 日報の直接入力値
  def site_ledger_outsourcing_contract_cost
    confirmed_daily_reports.sum(:outsourcing_cost).to_i
  end

  # 現場台帳：外注費合計
  def site_ledger_outsourcing_cost
    site_ledger_outsourcing_man_days_cost + site_ledger_outsourcing_contract_cost
  end

  # ========================================
  # その他原価（日報の直接入力値）
  # ========================================

  # 現場台帳：材料費（日報の直接入力値）
  def site_ledger_material_cost
    confirmed_daily_reports.sum(:material_cost).to_i
  end

  # 現場台帳：運搬費（日報の直接入力値）
  def site_ledger_transportation_cost
    confirmed_daily_reports.sum(:transportation_cost).to_i
  end

  # 現場台帳：機械費（自社）
  def site_ledger_machinery_own_cost
    confirmed_daily_reports.sum(:machinery_own_cost).to_i
  end

  # 現場台帳：機械費（レンタル）
  def site_ledger_machinery_rental_cost
    confirmed_daily_reports.sum(:machinery_rental_cost).to_i
  end

  # 現場台帳：機械費合計
  def site_ledger_machinery_cost
    site_ledger_machinery_own_cost + site_ledger_machinery_rental_cost
  end

  # 現場台帳：その他経費（ガソリン・高速代など）
  # 確定済みなら確定金額、未確定なら仮金額を使用
  # fuel_entries / highway_entries（新方式）と旧カラムの両方を集計
  def site_ledger_expense_cost
    reports = confirmed_daily_reports
    report_ids = reports.select(:id)

    # === 燃料費 ===
    # 新方式: fuel_entriesテーブルから集計
    fuel_from_entries = FuelEntry.where(daily_report_id: report_ids).sum(
      Arel.sql("CASE WHEN confirmed THEN COALESCE(confirmed_amount, 0) ELSE COALESCE(amount, 0) END")
    ).to_i

    # 旧方式: daily_reports.fuel_amountカラムから集計（fuel_entriesがない日報のみ）
    reports_with_fuel = FuelEntry.where(daily_report_id: report_ids).select(:daily_report_id).distinct
    fuel_from_legacy = reports.where.not(id: reports_with_fuel).sum(Arel.sql(
      "CASE WHEN fuel_confirmed THEN COALESCE(fuel_confirmed_amount, 0) ELSE COALESCE(fuel_amount, 0) END"
    )).to_i

    # === 高速代 ===
    # 新方式: highway_entriesテーブルから集計
    highway_from_entries = HighwayEntry.where(daily_report_id: report_ids).sum(
      Arel.sql("CASE WHEN confirmed THEN COALESCE(confirmed_amount, 0) ELSE COALESCE(amount, 0) END")
    ).to_i

    # 旧方式: daily_reports.highway_amountカラムから集計（highway_entriesがない日報のみ）
    reports_with_highway = HighwayEntry.where(daily_report_id: report_ids).select(:daily_report_id).distinct
    highway_from_legacy = reports.where.not(id: reports_with_highway).sum(Arel.sql(
      "CASE WHEN highway_confirmed THEN COALESCE(highway_confirmed_amount, 0) ELSE COALESCE(highway_amount, 0) END"
    )).to_i

    fuel_from_entries + fuel_from_legacy + highway_from_entries + highway_from_legacy
  end

  # 現場台帳：原価合計
  def site_ledger_total_cost
    site_ledger_labor_cost + site_ledger_outsourcing_cost +
      site_ledger_material_cost + site_ledger_transportation_cost +
      site_ledger_machinery_cost + site_ledger_expense_cost
  end

  # ========================================
  # 勤怠管理用（参考情報）
  # ========================================

  # 仮社員の人工数（勤怠管理・相殺用）
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

  # ========================================
  # 経費詳細（参考情報）
  # ========================================

  # 日報経費をカテゴリ別に集計（参考）
  def site_ledger_expenses_by_category
    @site_ledger_expenses_by_category ||= begin
      result = Hash.new(0)

      # 日報に紐づく経費
      Expense.where(daily_report_id: confirmed_daily_reports.select(:id))
             .group(:category)
             .sum(:amount)
             .each { |cat, amt| result[cat] += amt.to_i }

      result
    end
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
      material: (budget.material_cost || 0) - site_ledger_material_cost,
      outsourcing: (budget.outsourcing_cost || 0) - site_ledger_outsourcing_cost,
      machinery_own: (budget.machinery_own_cost || 0) - site_ledger_machinery_own_cost,
      machinery_rental: (budget.machinery_rental_cost || 0) - site_ledger_machinery_rental_cost,
      expense: (budget.expense_cost || 0) - site_ledger_expense_cost,
      total: (budget.total_cost || 0) - site_ledger_total_cost
    }
  end

  # ========================================
  # 出来高・仕掛かり管理
  # ========================================

  # 累計出来高（月次出来高の合計）
  def cumulative_progress_amount
    monthly_progresses.sum(:progress_amount).to_i
  end

  # 累計請求額（発行済み請求書の合計）
  def cumulative_invoiced_amount
    invoices.where(status: %w[issued paid]).sum(:total_amount).to_i
  end

  # 仕掛かり金額（累計出来高 - 累計請求額）
  def wip_amount
    cumulative_progress_amount - cumulative_invoiced_amount
  end

  # 進捗率（累計出来高 / 受注金額）
  def progress_rate
    return nil unless order_amount && order_amount.positive?

    ((cumulative_progress_amount.to_d / order_amount) * 100).round(1)
  end

  # 仕掛かり対象か（施工中で請求前の案件）
  def wip_target?
    %w[ordered preparing in_progress].include?(status)
  end

  # ラベルメソッド
  def contract_tier_label
    CONTRACT_TIER_LABELS[contract_tier]
  end

  def engineer_type_label
    ENGINEER_TYPE_LABELS[engineer_type]
  end

  def safety_doc_status_label
    SAFETY_DOC_STATUS_LABELS[safety_doc_status]
  end

  def safety_doc_method_label
    SAFETY_DOC_METHOD_LABELS[safety_doc_method]
  end

  private

  def generate_code
    return if code.present?

    prefix = "PJ"
    date_part = Date.current.strftime("%Y%m")
    seq = Project.where("code LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.code = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end

  # === LINE WORKS通知 ===

  def notify_project_created
    NotificationJob.perform_later(
      event_type: "project_created",
      record_type: "Project",
      record_id: id
    )
  end

  def notify_status_changes
    # 4点チェック完了
    if saved_change_to_four_point_completed_at? && four_point_completed_at.present?
      NotificationJob.perform_later(
        event_type: "four_point_completed",
        record_type: "Project",
        record_id: id
      )
    end

    # 着工前ゲート完了
    if saved_change_to_pre_construction_gate_completed_at? && pre_construction_gate_completed_at.present?
      NotificationJob.perform_later(
        event_type: "pre_construction_completed",
        record_type: "Project",
        record_id: id
      )
    end

    # 着工
    if saved_change_to_actual_start_date? && actual_start_date.present?
      NotificationJob.perform_later(
        event_type: "construction_started",
        record_type: "Project",
        record_id: id
      )
    end

    # 完工
    if saved_change_to_actual_end_date? && actual_end_date.present?
      NotificationJob.perform_later(
        event_type: "project_completed",
        record_type: "Project",
        record_id: id
      )
    end
  end

  # === Google Drive連携 ===

  def create_drive_folder
    GoogleDriveSyncJob.perform_later(
      action: "create_project_folder",
      record_type: "Project",
      record_id: id
    )
  end
end
