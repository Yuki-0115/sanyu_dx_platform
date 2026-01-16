# frozen_string_literal: true

class Project < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  STATUSES = %w[draft estimating ordered preparing in_progress completed invoiced paid closed].freeze
  PROJECT_TYPES = %w[regular misc].freeze
  PROJECT_TYPE_LABELS = {
    "regular" => "通常案件",
    "misc" => "その他（小工事・常用）"
  }.freeze

  # Associations
  belongs_to :client
  belongs_to :sales_user, class_name: "Employee", optional: true
  belongs_to :engineering_user, class_name: "Employee", optional: true
  belongs_to :construction_user, class_name: "Employee", optional: true

  has_one :budget, dependent: :destroy
  has_one :estimate, dependent: :destroy
  has_many :daily_reports, dependent: :restrict_with_error
  has_many :expenses, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error
  has_many :project_assignments, dependent: :destroy
  has_many :assigned_employees, through: :project_assignments, source: :employee

  # Validations
  validates :code, presence: true, uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :project_type, inclusion: { in: PROJECT_TYPES }

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :project_type, :string, default: "regular"
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
end
