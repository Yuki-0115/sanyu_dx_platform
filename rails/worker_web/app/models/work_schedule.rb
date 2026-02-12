# frozen_string_literal: true

class WorkSchedule < ApplicationRecord
  SHIFTS = %w[day night].freeze
  SHIFT_LABELS = { "day" => "日勤", "night" => "夜勤" }.freeze

  belongs_to :employee, class_name: "Worker"
  belongs_to :project, optional: true

  scope :for_date_range, ->(range) { where(scheduled_date: range) }
  scope :day_shift, -> { where(shift: "day") }
  scope :night_shift, -> { where(shift: "night") }

  def shift_label
    SHIFT_LABELS[shift] || shift
  end

  def foreman?
    role == "foreman"
  end
end
