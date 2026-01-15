# frozen_string_literal: true

class Attendance < ApplicationRecord
  include TenantScoped

  # Constants
  ATTENDANCE_TYPES = %w[full half absent].freeze

  # Associations
  belongs_to :daily_report
  belongs_to :employee

  # Validations
  validates :attendance_type, presence: true, inclusion: { in: ATTENDANCE_TYPES }
  validates :employee_id, uniqueness: { scope: %i[tenant_id daily_report_id] }

  # Scopes
  scope :present, -> { where(attendance_type: %w[full half]) }

  # Instance methods
  def present?
    attendance_type.in?(%w[full half])
  end
end
