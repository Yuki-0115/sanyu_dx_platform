# frozen_string_literal: true

class DailyScheduleNote < ApplicationRecord
  belongs_to :project

  scope :for_date_range, ->(range) { where(scheduled_date: range) }

  def has_content?
    work_content.present? || vehicles.present? || equipment.present? || notes.present?
  end
end
