# frozen_string_literal: true

class DailyScheduleNote < ApplicationRecord
  include TenantScoped

  # Associations
  belongs_to :project

  # Validations
  validates :scheduled_date, presence: true
  validates :project_id, uniqueness: { scope: [:tenant_id, :scheduled_date], message: "は同じ日に既に備考があります" }

  # Scopes
  scope :for_date, ->(date) { where(scheduled_date: date) }
  scope :for_date_range, ->(range) { where(scheduled_date: range) }

  # 入力がある項目があるかどうか
  def has_content?
    work_content.present? || vehicles.present? || equipment.present? ||
      heavy_equipment_transport.present? || notes.present?
  end
end
