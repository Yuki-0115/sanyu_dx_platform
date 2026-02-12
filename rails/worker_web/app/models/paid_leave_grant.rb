# frozen_string_literal: true

class PaidLeaveGrant < ApplicationRecord
  belongs_to :employee, class_name: "Worker", foreign_key: :employee_id

  scope :active, -> { where("expiry_date >= ?", Date.current) }
  scope :with_remaining, -> { where("remaining_days > 0") }
  scope :oldest_first, -> { order(grant_date: :asc) }

  def restore!(days)
    self.used_days -= days
    self.remaining_days += days
    save!
  end
end
