# frozen_string_literal: true

class OutsourcingSchedule < ApplicationRecord
  # Constants
  SHIFTS = %w[day night].freeze
  SHIFT_LABELS = {
    "day" => "日勤",
    "night" => "夜勤"
  }.freeze

  BILLING_TYPES = %w[man_days contract].freeze
  BILLING_TYPE_LABELS = {
    "man_days" => "人工",
    "contract" => "請負"
  }.freeze

  # Associations
  belongs_to :project
  belongs_to :partner

  # Validations
  validates :scheduled_date, presence: true
  validates :shift, presence: true, inclusion: { in: SHIFTS }
  validates :billing_type, presence: true, inclusion: { in: BILLING_TYPES }
  validates :headcount, numericality: { greater_than: 0 }, if: :man_days?
  validates :partner_id, uniqueness: {
    scope: %i[scheduled_date shift project_id],
    message: "は同じ案件・日・勤務帯に既に登録されています"
  }

  # Scopes
  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :for_date_range, ->(range) { where(scheduled_date: range) }
  scope :day_shift, -> { where(shift: "day") }
  scope :night_shift, -> { where(shift: "night") }
  scope :ordered, -> { includes(:partner).order("partners.name") }

  # Instance methods
  def shift_label
    SHIFT_LABELS[shift] || shift
  end

  def billing_type_label
    BILLING_TYPE_LABELS[billing_type] || billing_type
  end

  def day_shift?
    shift == "day"
  end

  def night_shift?
    shift == "night"
  end

  def man_days?
    billing_type == "man_days"
  end

  def contract?
    billing_type == "contract"
  end

  # 表示用ラベル
  def display_label
    if contract?
      "#{partner.name}（請負）"
    else
      "#{partner.name}×#{headcount}"
    end
  end

  # 短縮表示（セル用）
  def short_label
    if contract?
      "#{partner.name.first(3)}請"
    else
      "#{partner.name.first(3)}×#{headcount}"
    end
  end
end
