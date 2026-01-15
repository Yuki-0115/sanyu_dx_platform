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
  belongs_to :project, optional: true  # 常用（外部現場）の場合はnil
  belongs_to :foreman, class_name: "Employee"
  belongs_to :revised_by, class_name: "Employee", optional: true

  has_many :attendances, dependent: :destroy
  has_many :expenses, dependent: :destroy

  accepts_nested_attributes_for :attendances, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["attendance_type"].blank? }

  # Validations
  validates :report_date, presence: true
  validates :report_date, uniqueness: { scope: %i[tenant_id project_id] }, unless: :is_external?
  validates :status, inclusion: { in: STATUSES }
  validates :weather, inclusion: { in: WEATHERS }, allow_blank: true
  validates :external_site_name, presence: true, if: :is_external?
  validates :project_id, presence: true, unless: :is_external?

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :is_external, :boolean, default: false

  # Scopes
  scope :draft, -> { where(status: "draft") }
  scope :confirmed, -> { where(status: "confirmed") }
  scope :by_date, ->(date) { where(report_date: date) }
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
    (labor_cost || 0) + (material_cost || 0) + (outsourcing_cost || 0) + (transportation_cost || 0)
  end
end
