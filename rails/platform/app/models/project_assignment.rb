# frozen_string_literal: true

class ProjectAssignment < ApplicationRecord

  # Constants
  ROLES = %w[foreman worker support].freeze
  SHIFTS = %w[day night].freeze
  SHIFT_LABELS = {
    "day" => "日勤",
    "night" => "夜勤"
  }.freeze

  # Associations
  belongs_to :project
  belongs_to :employee

  # Validations
  validates :employee_id, uniqueness: { scope: %i[project_id shift], message: "は既にこの案件・勤務帯に配置されています" }
  validates :shift, inclusion: { in: SHIFTS }

  # Scopes
  scope :active_on, ->(date) { where("(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)", date, date) }
  scope :foremen, -> { where(role: "foreman") }
  scope :workers, -> { where(role: %w[worker support]) }
  scope :day_shift, -> { where(shift: "day") }
  scope :night_shift, -> { where(shift: "night") }

  # Callbacks
  before_validation :set_default_dates
  before_validation :set_default_shift

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

  private

  def set_default_dates
    self.start_date ||= project&.scheduled_start_date || Date.current
    self.end_date ||= project&.scheduled_end_date
  end

  def set_default_shift
    self.shift ||= "day"
  end
end
