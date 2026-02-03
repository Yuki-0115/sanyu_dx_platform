# frozen_string_literal: true

class PaidLeaveGrant < ApplicationRecord
  belongs_to :employee
  has_many :paid_leave_requests, dependent: :restrict_with_error

  GRANT_TYPES = %w[auto manual special].freeze

  validates :grant_date, presence: true
  validates :expiry_date, presence: true
  validates :granted_days, presence: true, numericality: { greater_than: 0 }
  validates :used_days, numericality: { greater_than_or_equal_to: 0 }
  validates :remaining_days, numericality: { greater_than_or_equal_to: 0 }
  validates :fiscal_year, presence: true
  validates :grant_type, inclusion: { in: GRANT_TYPES }
  validates :grant_date, uniqueness: { scope: :employee_id }

  validate :expiry_date_after_grant_date
  validate :remaining_days_not_exceed_granted

  scope :active, -> { where("expiry_date >= ?", Date.current) }
  scope :with_remaining, -> { where("remaining_days > 0") }
  scope :oldest_first, -> { order(grant_date: :asc) }
  scope :for_fiscal_year, ->(year) { where(fiscal_year: year) }

  # 消化処理（古い付与分から消化）
  def consume!(days)
    raise "残日数が不足しています" if remaining_days < days

    self.used_days += days
    self.remaining_days -= days
    save!
  end

  # 消化を取り消し（キャンセル時）
  def restore!(days)
    self.used_days -= days
    self.remaining_days += days
    save!
  end

  # 期限切れかどうか
  def expired?
    expiry_date < Date.current
  end

  # 付与種別の日本語表示
  def grant_type_label
    {
      "auto" => "自動付与",
      "manual" => "手動付与",
      "special" => "特別付与"
    }[grant_type]
  end

  private

  def expiry_date_after_grant_date
    return unless grant_date && expiry_date

    errors.add(:expiry_date, "は付与日より後である必要があります") if expiry_date <= grant_date
  end

  def remaining_days_not_exceed_granted
    return unless granted_days && remaining_days

    if remaining_days > granted_days
      errors.add(:remaining_days, "は付与日数を超えることはできません")
    end
  end
end
