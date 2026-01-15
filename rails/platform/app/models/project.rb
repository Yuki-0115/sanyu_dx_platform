# frozen_string_literal: true

class Project < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  STATUSES = %w[draft estimating ordered preparing in_progress completed invoiced paid closed].freeze

  # Associations
  belongs_to :client
  belongs_to :sales_user, class_name: "Employee", optional: true
  belongs_to :engineering_user, class_name: "Employee", optional: true
  belongs_to :construction_user, class_name: "Employee", optional: true

  has_one :budget, dependent: :destroy
  has_many :daily_reports, dependent: :restrict_with_error
  has_many :expenses, dependent: :restrict_with_error
  has_many :invoices, dependent: :restrict_with_error

  # Validations
  validates :code, presence: true, uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :has_contract, :boolean, default: false
  attribute :has_order, :boolean, default: false
  attribute :has_payment_terms, :boolean, default: false
  attribute :has_customer_approval, :boolean, default: false

  # Scopes
  scope :active, -> { where.not(status: %w[closed paid]) }
  scope :in_progress, -> { where(status: "in_progress") }

  # Instance methods
  def four_point_completed?
    has_contract && has_order && has_payment_terms && has_customer_approval
  end

  def complete_four_point_check!
    return false unless four_point_completed?

    update!(four_point_completed_at: Time.current, status: "ordered")
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
