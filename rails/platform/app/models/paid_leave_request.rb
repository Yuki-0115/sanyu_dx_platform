# frozen_string_literal: true

class PaidLeaveRequest < ApplicationRecord
  belongs_to :employee
  belongs_to :approved_by, class_name: "Employee", optional: true
  belongs_to :paid_leave_grant, optional: true

  LEAVE_TYPES = %w[full half_am half_pm].freeze
  STATUSES = %w[pending approved rejected cancelled].freeze

  validates :leave_date, presence: true
  validates :leave_type, presence: true, inclusion: { in: LEAVE_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :consumed_days, presence: true, numericality: { greater_than: 0 }
  validates :leave_date, uniqueness: { scope: :employee_id, message: "は既に申請済みです" }

  validate :leave_date_not_in_past, on: :create
  validate :rejection_reason_required_when_rejected

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :for_period, ->(start_date, end_date) { where(leave_date: start_date..end_date) }

  before_validation :set_consumed_days

  # 承認処理
  def approve!(approver)
    transaction do
      grant = find_consumable_grant!
      grant.consume!(consumed_days)

      update!(
        status: "approved",
        approved_by_id: approver.id,
        approved_at: Time.current,
        paid_leave_grant_id: grant.id
      )
    end
  end

  # 却下処理
  def reject!(approver, reason)
    update!(
      status: "rejected",
      approved_by_id: approver.id,
      approved_at: Time.current,
      rejection_reason: reason
    )
  end

  # キャンセル処理
  def cancel!
    transaction do
      if status == "approved" && paid_leave_grant.present?
        paid_leave_grant.restore!(consumed_days)
      end
      update!(status: "cancelled")
    end
  end

  def full_day?
    leave_type == "full"
  end

  def half_day?
    leave_type.in?(%w[half_am half_pm])
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def cancelled?
    status == "cancelled"
  end

  # 休暇種別の日本語表示
  def leave_type_label
    {
      "full" => "全休",
      "half_am" => "午前半休",
      "half_pm" => "午後半休"
    }[leave_type]
  end

  # ステータスの日本語表示
  def status_label
    {
      "pending" => "承認待ち",
      "approved" => "承認済",
      "rejected" => "却下",
      "cancelled" => "キャンセル"
    }[status]
  end

  # ステータスに応じたバッジの色クラス
  def status_badge_class
    {
      "pending" => "bg-yellow-100 text-yellow-800",
      "approved" => "bg-green-100 text-green-800",
      "rejected" => "bg-red-100 text-red-800",
      "cancelled" => "bg-gray-100 text-gray-800"
    }[status]
  end

  private

  def set_consumed_days
    self.consumed_days = full_day? ? 1.0 : 0.5
  end

  def leave_date_not_in_past
    return unless leave_date

    errors.add(:leave_date, "は過去の日付を指定できません") if leave_date < Date.current
  end

  def rejection_reason_required_when_rejected
    return unless status == "rejected"

    errors.add(:rejection_reason, "は却下時に必須です") if rejection_reason.blank?
  end

  def find_consumable_grant!
    grant = employee.paid_leave_grants
                    .active
                    .with_remaining
                    .oldest_first
                    .first

    raise "有給残日数が不足しています" unless grant
    raise "残日数が不足しています" if grant.remaining_days < consumed_days

    grant
  end
end
