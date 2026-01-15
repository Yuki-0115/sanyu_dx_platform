# frozen_string_literal: true

class Offset < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  STATUSES = %w[draft confirmed].freeze

  # Associations
  belongs_to :partner
  belongs_to :confirmed_by, class_name: "Employee", optional: true

  # Validations
  validates :year_month, presence: true, format: { with: /\A\d{4}-\d{2}\z/ }
  validates :year_month, uniqueness: { scope: %i[tenant_id partner_id] }
  validates :status, inclusion: { in: STATUSES }

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :total_salary, :decimal, default: 0
  attribute :social_insurance, :decimal, default: 0
  attribute :offset_amount, :decimal, default: 0
  attribute :revenue_amount, :decimal, default: 0
  attribute :balance, :decimal, default: 0

  # Callbacks
  before_save :calculate_offset

  # Scopes
  scope :for_month, ->(year_month) { where(year_month: year_month) }
  scope :confirmed, -> { where(status: "confirmed") }

  # Instance methods
  def confirm!(user)
    update!(status: "confirmed", confirmed_by: user, confirmed_at: Time.current)
  end

  private

  def calculate_offset
    self.offset_amount = total_salary.to_d + social_insurance.to_d
    self.balance = revenue_amount.to_d - offset_amount.to_d
  end
end
