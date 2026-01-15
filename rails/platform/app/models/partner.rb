# frozen_string_literal: true

class Partner < ApplicationRecord
  include TenantScoped
  include Auditable

  # Associations
  has_many :employees, dependent: :nullify
  has_many :offsets, dependent: :restrict_with_error

  # Validations
  validates :code, presence: true, uniqueness: { scope: :tenant_id }
  validates :name, presence: true

  # Defaults
  attribute :has_temporary_employees, :boolean, default: false
  attribute :carryover_balance, :decimal, default: 0
end
