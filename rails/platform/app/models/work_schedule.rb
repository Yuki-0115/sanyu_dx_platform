# frozen_string_literal: true

class WorkSchedule < ApplicationRecord
  include TenantScoped

  # Constants
  SHIFTS = %w[day night].freeze
  SHIFT_LABELS = {
    "day" => "日勤",
    "night" => "夜勤"
  }.freeze

  # Associations
  belongs_to :employee
  belongs_to :project, optional: true

  # Validations
  validates :scheduled_date, presence: true
  validates :shift, presence: true, inclusion: { in: SHIFTS }
  validates :employee_id, uniqueness: {
    scope: %i[tenant_id scheduled_date shift project_id],
    message: "は同じ案件・日・勤務帯に既に登録されています"
  }

  # Scopes
  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :for_date_range, ->(range) { where(scheduled_date: range) }
  scope :day_shift, -> { where(shift: "day") }
  scope :night_shift, -> { where(shift: "night") }
  scope :ordered, -> { includes(:employee).order("employees.name") }

  # Instance methods
  def shift_label
    SHIFT_LABELS[shift] || shift
  end

  def day_shift?
    shift == "day"
  end

  def night_shift?
    shift == "night"
  end
end
