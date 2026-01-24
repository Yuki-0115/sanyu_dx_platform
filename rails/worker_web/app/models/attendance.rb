# frozen_string_literal: true

class Attendance < ApplicationRecord
  belongs_to :daily_report
  belongs_to :employee, class_name: "Worker", optional: true

  # Worker Webでは worker として参照できるようにエイリアス
  alias_method :worker, :employee

  TYPES = %w[full half overtime holiday night].freeze
end
