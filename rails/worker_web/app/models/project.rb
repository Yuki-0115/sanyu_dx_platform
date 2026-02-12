# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :client, optional: true
  has_many :daily_reports
  has_many :work_schedules
  has_many :outsourcing_schedules
  has_many :daily_schedule_notes
end
