# frozen_string_literal: true

class OutsourcingEntry < ApplicationRecord

  # Constants
  ATTENDANCE_TYPES = %w[full half].freeze
  ATTENDANCE_LABELS = {
    "full" => "1日",
    "half" => "半日"
  }.freeze

  # Associations
  belongs_to :daily_report
  belongs_to :partner, optional: true  # マスタから選択（任意）

  # Validations
  validates :headcount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :attendance_type, presence: true, inclusion: { in: ATTENDANCE_TYPES }
  validate :partner_or_partner_name_present

  # Callbacks
  before_validation :normalize_partner_name

  # Scopes
  scope :by_partner, ->(partner) { where(partner: partner) }
  scope :by_partner_name, ->(name) { where(partner_name: name) }

  # 会社名（マスタからの名前 or 手入力名）
  def company_name
    partner&.name || partner_name
  end

  # 人工計算（1日=1人工、半日=0.5人工）
  def man_days
    case attendance_type
    when "full"
      headcount
    when "half"
      headcount * 0.5
    else
      0
    end
  end

  # 表示用ラベル
  def attendance_label
    ATTENDANCE_LABELS[attendance_type] || attendance_type
  end

  private

  def partner_or_partner_name_present
    if partner_id.blank? && partner_name.blank?
      errors.add(:base, "協力会社を選択するか、手入力で会社名を入力してください")
    end
  end

  def normalize_partner_name
    self.partner_name = partner_name.strip if partner_name.present?
  end
end
