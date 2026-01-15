# frozen_string_literal: true

class Budget < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  STATUSES = %w[draft confirmed].freeze

  # Associations
  belongs_to :project
  belongs_to :confirmed_by, class_name: "Employee", optional: true

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

  # Callbacks
  before_save :calculate_total_cost

  # Instance methods
  def confirm!(user)
    update!(status: "confirmed", confirmed_by: user, confirmed_at: Time.current)
  end

  private

  def calculate_total_cost
    self.total_cost = material_cost.to_d + outsourcing_cost.to_d + labor_cost.to_d + expense_cost.to_d
  end
end
