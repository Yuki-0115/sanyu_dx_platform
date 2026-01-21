# frozen_string_literal: true

class DailyReport < ApplicationRecord
  include Auditable

  # Constants
  STATUSES = %w[draft confirmed revised].freeze
  WEATHERS = %w[sunny cloudy rainy snowy].freeze
  WEATHER_LABELS = {
    "sunny" => "晴れ",
    "cloudy" => "曇り",
    "rainy" => "雨",
    "snowy" => "雪"
  }.freeze
  FUEL_TYPES = %w[regular high_octane diesel].freeze
  FUEL_TYPE_LABELS = {
    "regular" => "レギュラー",
    "high_octane" => "ハイオク",
    "diesel" => "軽油"
  }.freeze

  # Associations
  belongs_to :project, optional: true  # 常用（外部現場）の場合はnil
  belongs_to :foreman, class_name: "Employee"
  belongs_to :revised_by, class_name: "Employee", optional: true

  has_many :attendances, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :outsourcing_entries, dependent: :destroy

  # 写真添付（複数）
  has_many_attached :photos

  accepts_nested_attributes_for :attendances, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["attendance_type"].blank? }
  accepts_nested_attributes_for :expenses, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["amount"].blank? || attrs["amount"].to_i <= 0 }
  accepts_nested_attributes_for :outsourcing_entries, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["headcount"].blank? || attrs["headcount"].to_i <= 0 }

  # Validations
  validates :report_date, presence: true
  validates :report_date, uniqueness: { scope: :project_id, message: "この案件の同日の日報は既に存在します。編集画面から更新してください。" }, unless: :is_external?
  validates :status, inclusion: { in: STATUSES }
  validates :weather, inclusion: { in: WEATHERS }, allow_blank: true
  validates :external_site_name, presence: true, if: :is_external?
  validates :project_id, presence: true, unless: :is_external?

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :is_external, :boolean, default: false

  # Scopes
  scope :confirmed, -> { where(status: "confirmed") }
  scope :internal, -> { where(is_external: false) }
  scope :external, -> { where(is_external: true) }

  # 現場名（案件名 or 外部現場名）
  def site_name
    is_external? ? external_site_name : project&.name
  end

  # Instance methods
  def confirm!
    update!(status: "confirmed", confirmed_at: Time.current)
  end

  def confirmed?
    status == "confirmed"
  end

  def revised?
    status == "revised"
  end

  def finalized?
    confirmed? || revised?
  end

  def revise!(user)
    return unless finalized?

    update!(
      status: "revised",
      revised_at: Time.current,
      revised_by: user
    )
  end

  # 確定済み/修正済みの場合に編集したら自動的にrevisedにする
  def mark_as_revised_if_needed(user)
    if confirmed? && changed?
      self.status = "revised"
      self.revised_at = Time.current
      self.revised_by = user
    end
  end

  # 日報の原価合計
  def total_cost
    (labor_cost || 0) + (material_cost || 0) + (outsourcing_cost || 0) + (transportation_cost || 0) +
      fuel_cost_for_calculation + highway_cost_for_calculation
  end

  # 燃料費（計算用：確定金額があればそれを使用、なければ仮金額）
  def fuel_cost_for_calculation
    fuel_confirmed? ? (fuel_confirmed_amount || 0) : (fuel_amount || 0)
  end

  # 高速代（計算用：確定金額があればそれを使用、なければ仮金額）
  def highway_cost_for_calculation
    highway_confirmed? ? (highway_confirmed_amount || 0) : (highway_amount || 0)
  end

  # 燃料費を確定（単価から確定金額を計算）
  def confirm_fuel!(unit_price)
    confirmed_amount = (fuel_quantity || 0) * unit_price
    update!(
      fuel_confirmed: true,
      fuel_unit_price: unit_price,
      fuel_confirmed_amount: confirmed_amount
    )
  end

  # 油種のラベル
  def fuel_type_label
    FUEL_TYPE_LABELS[fuel_type] || fuel_type
  end

  # 高速代を確定
  def confirm_highway!(confirmed_amount)
    update!(
      highway_confirmed: true,
      highway_confirmed_amount: confirmed_amount
    )
  end

  # 燃料費が入力されているか
  def has_fuel?
    fuel_quantity.present? && fuel_quantity.positive?
  end

  # 高速代が入力されているか
  def has_highway?
    highway_count.present? && highway_count.positive?
  end

  # 仮経費（未確定の燃料費・高速代）があるか
  def has_provisional_card_expenses?
    (has_fuel? && !fuel_confirmed?) || (has_highway? && !highway_confirmed?)
  end
end
