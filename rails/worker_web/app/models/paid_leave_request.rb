# frozen_string_literal: true

class PaidLeaveRequest < ApplicationRecord
  LEAVE_TYPES = %w[full half_am half_pm].freeze
  LEAVE_TYPE_LABELS = { "full" => "全休", "half_am" => "午前半休", "half_pm" => "午後半休" }.freeze
  STATUSES = %w[pending approved rejected cancelled].freeze
  STATUS_LABELS = { "pending" => "承認待ち", "approved" => "承認済", "rejected" => "却下", "cancelled" => "キャンセル" }.freeze
  STATUS_BADGE_CLASSES = {
    "pending" => "bg-yellow-100 text-yellow-800",
    "approved" => "bg-green-100 text-green-800",
    "rejected" => "bg-red-100 text-red-800",
    "cancelled" => "bg-gray-100 text-gray-800"
  }.freeze

  belongs_to :employee, class_name: "Worker", foreign_key: :employee_id
  belongs_to :approved_by, class_name: "Worker", foreign_key: :approved_by_id, optional: true
  belongs_to :paid_leave_grant, optional: true

  validates :leave_date, presence: true
  validates :leave_type, presence: true, inclusion: { in: LEAVE_TYPES }
  validates :consumed_days, presence: true, numericality: { greater_than: 0 }
  validates :leave_date, uniqueness: { scope: :employee_id, message: "は既に申請済みです" }
  validate :leave_date_not_in_past, on: :create

  before_validation :set_consumed_days

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }

  def cancel!
    transaction do
      if status == "approved" && paid_leave_grant.present?
        paid_leave_grant.restore!(consumed_days)
      end
      update!(status: "cancelled")
    end
  end

  def pending?
    status == "pending"
  end

  def leave_type_label
    LEAVE_TYPE_LABELS[leave_type] || leave_type
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def status_badge_class
    STATUS_BADGE_CLASSES[status] || "bg-gray-100 text-gray-800"
  end

  private

  def set_consumed_days
    self.consumed_days = leave_type == "full" ? 1.0 : 0.5
  end

  def leave_date_not_in_past
    return unless leave_date

    errors.add(:leave_date, "は過去の日付を指定できません") if leave_date < Date.current
  end
end
