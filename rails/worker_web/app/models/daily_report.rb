# frozen_string_literal: true

class DailyReport < ApplicationRecord
  STATUSES = %w[draft confirmed revised].freeze
  WEATHERS = %w[sunny cloudy rainy snowy].freeze
  WEATHER_LABELS = { "sunny" => "晴れ", "cloudy" => "曇り", "rainy" => "雨", "snowy" => "雪" }.freeze
  FUEL_TYPES = %w[regular high_octane diesel].freeze
  FUEL_TYPE_LABELS = { "regular" => "レギュラー", "high_octane" => "ハイオク", "diesel" => "軽油" }.freeze

  belongs_to :project, optional: true
  belongs_to :foreman, class_name: "Worker", foreign_key: :foreman_id

  has_many :attendances, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :outsourcing_entries, dependent: :destroy
  has_many :fuel_entries, dependent: :destroy
  has_many :highway_entries, dependent: :destroy
  has_many_attached :photos
  has_one_attached :fuel_receipt
  has_one_attached :highway_receipt

  accepts_nested_attributes_for :attendances, allow_destroy: true,
    reject_if: ->(attrs) { attrs["attendance_type"].blank? }
  accepts_nested_attributes_for :expenses, allow_destroy: true,
    reject_if: ->(attrs) { attrs["amount_pending"] != "1" && (attrs["amount"].blank? || attrs["amount"].to_i <= 0) }
  accepts_nested_attributes_for :outsourcing_entries, allow_destroy: true,
    reject_if: ->(attrs) { attrs["partner_id"].blank? && attrs["partner_name"].blank? }
  accepts_nested_attributes_for :fuel_entries, allow_destroy: true,
    reject_if: ->(attrs) { attrs["amount"].blank? || attrs["amount"].to_i <= 0 }
  accepts_nested_attributes_for :highway_entries, allow_destroy: true,
    reject_if: ->(attrs) { attrs["amount"].blank? || attrs["amount"].to_i <= 0 }

  validates :report_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :external_site_name, presence: true, if: :is_external?

  attribute :status, :string, default: "draft"
  attribute :is_external, :boolean, default: false

  scope :by_date, -> { order(report_date: :desc) }

  def draft?
    status == "draft"
  end

  def confirmed?
    status == "confirmed"
  end

  def confirm!
    update!(status: "confirmed", confirmed_at: Time.current)
  end

  def site_name
    is_external? ? external_site_name : project&.name
  end

  def weather_label
    WEATHER_LABELS[weather] || weather
  end
end
