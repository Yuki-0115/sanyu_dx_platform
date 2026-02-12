# frozen_string_literal: true

class OutsourcingSchedule < ApplicationRecord
  SHIFTS = %w[day night].freeze
  BILLING_TYPES = %w[man_days contract].freeze

  belongs_to :project
  belongs_to :partner

  scope :for_date_range, ->(range) { where(scheduled_date: range) }

  def short_label
    billing_type == "contract" ? "#{partner.name.first(3)}請" : "#{partner.name.first(3)}x#{headcount}"
  end
end
