# frozen_string_literal: true

class DailyReport < ApplicationRecord
  include TenantScoped
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

  # Associations
  belongs_to :project
  belongs_to :foreman, class_name: "Employee"
  belongs_to :revised_by, class_name: "Employee", optional: true

  has_many :attendances, dependent: :destroy
  has_many :expenses, dependent: :destroy

  accepts_nested_attributes_for :attendances, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["attendance_type"].blank? }

  # Validations
  validates :report_date, presence: true
  validates :report_date, uniqueness: { scope: %i[tenant_id project_id] }
  validates :status, inclusion: { in: STATUSES }
  validates :weather, inclusion: { in: WEATHERS }, allow_blank: true

  # Defaults
  attribute :status, :string, default: "draft"

  # Scopes
  scope :draft, -> { where(status: "draft") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :by_date, ->(date) { where(report_date: date) }

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
    (labor_cost || 0) + (material_cost || 0) + (outsourcing_cost || 0) + (transportation_cost || 0)
  end
end
