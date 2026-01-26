# frozen_string_literal: true

class OutsourcingEntry < ApplicationRecord

  # Constants
  ATTENDANCE_TYPES = %w[full half].freeze
  ATTENDANCE_LABELS = {
    "full" => "1日",
    "half" => "半日"
  }.freeze

  BILLING_TYPES = %w[man_days contract].freeze
  BILLING_TYPE_LABELS = {
    "man_days" => "人工",
    "contract" => "請負"
  }.freeze

  UNITS = %w[m m² m³ 式 本 枚 個 台 人 日 回 t kg].freeze

  # Associations
  belongs_to :daily_report
  belongs_to :partner, optional: true  # マスタから選択（任意）

  # Defaults
  attribute :billing_type, :string, default: "man_days"

  # Validations
  validates :billing_type, presence: true, inclusion: { in: BILLING_TYPES }
  validates :headcount, presence: true, numericality: { greater_than: 0, only_integer: true }, if: :man_days_billing?
  validates :attendance_type, presence: true, inclusion: { in: ATTENDANCE_TYPES }, if: :man_days_billing?
  validates :contract_amount, presence: true, numericality: { greater_than: 0 }, if: :contract_billing?
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

  def billing_type_label
    BILLING_TYPE_LABELS[billing_type] || billing_type
  end

  # 数量表示（数量 + 単位）
  def quantity_with_unit
    return nil if quantity.blank?

    "#{quantity.to_s(:delimited)}#{unit}"
  end

  # 請求種別判定
  def man_days_billing?
    billing_type == "man_days"
  end

  def contract_billing?
    billing_type == "contract"
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
