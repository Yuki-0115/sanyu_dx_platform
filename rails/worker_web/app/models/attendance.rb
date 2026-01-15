# frozen_string_literal: true

class Attendance < ApplicationRecord
  belongs_to :daily_report
  belongs_to :worker, optional: true

  TYPES = %w[full half overtime holiday night].freeze
end
