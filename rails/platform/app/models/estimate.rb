# frozen_string_literal: true

class Estimate < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  STATUSES = %w[draft submitted approved rejected].freeze

  # Associations
  belongs_to :project
  belongs_to :created_by, class_name: "Employee", optional: true

  # Validations
  validates :project_id, uniqueness: { scope: :tenant_id }
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :material_cost, :decimal, default: 0
  attribute :outsourcing_cost, :decimal, default: 0
  attribute :labor_cost, :decimal, default: 0
  attribute :expense_cost, :decimal, default: 0
  attribute :total_cost, :decimal, default: 0
  attribute :selling_price, :decimal, default: 0

  # Callbacks
  before_save :calculate_total_cost
  before_save :calculate_profit_margin

  # Scopes
  scope :approved, -> { where(status: "approved") }

  def approved?
    status == "approved"
  end

  def can_import_to_budget?
    approved? || status == "submitted"
  end

  private

  def calculate_total_cost
    self.total_cost = material_cost.to_d + outsourcing_cost.to_d + labor_cost.to_d + expense_cost.to_d
  end

  def calculate_profit_margin
    return if selling_price.to_d.zero?

    self.profit_margin = ((selling_price.to_d - total_cost.to_d) / selling_price.to_d * 100).round(2)
  end
end
