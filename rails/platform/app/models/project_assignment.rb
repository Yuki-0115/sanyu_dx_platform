# frozen_string_literal: true

class ProjectAssignment < ApplicationRecord
  include TenantScoped

  # Constants
  ROLES = %w[foreman worker support].freeze

  # Associations
  belongs_to :project
  belongs_to :employee

  # Validations
  validates :employee_id, uniqueness: { scope: %i[tenant_id project_id], message: "は既にこの案件に配置されています" }

  # Scopes
  scope :active_on, ->(date) { where("start_date <= ? AND (end_date IS NULL OR end_date >= ?)", date, date) }
  scope :foremen, -> { where(role: "foreman") }
  scope :workers, -> { where(role: %w[worker support]) }

  # Callbacks
  before_validation :set_default_dates

  private

  def set_default_dates
    self.start_date ||= project&.scheduled_start_date || Date.current
    self.end_date ||= project&.scheduled_end_date
  end
end
