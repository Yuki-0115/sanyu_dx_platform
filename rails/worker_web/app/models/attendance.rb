# frozen_string_literal: true

class Attendance < ApplicationRecord
  belongs_to :daily_report
  belongs_to :employee, class_name: "Worker", optional: true

  TYPES = %w[full half].freeze
  WORK_CATEGORIES = %w[work day_off paid_leave absence substitute_holiday].freeze
  WORK_CATEGORY_LABELS = {
    "work" => "出勤", "day_off" => "休日", "paid_leave" => "有給",
    "absence" => "欠勤", "substitute_holiday" => "振休"
  }.freeze

  alias_method :worker, :employee

  def worker_name
    employee&.name || "不明"
  end

  def work_category_label
    WORK_CATEGORY_LABELS[work_category] || work_category
  end
end
