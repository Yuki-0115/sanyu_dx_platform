# frozen_string_literal: true

# Worker Webでは「Worker」として扱うが、実際のテーブルはplatformの「employees」
class Worker < ApplicationRecord
  self.table_name = "employees"

  # Associations
  belongs_to :partner, optional: true
  has_many :attendances, foreign_key: :employee_id
  has_many :work_schedules, foreign_key: :employee_id
  has_many :daily_reports_as_foreman, class_name: "DailyReport", foreign_key: :foreman_id
  has_many :paid_leave_grants, foreign_key: :employee_id
  has_many :paid_leave_requests, foreign_key: :employee_id

  # Validations
  validates :code, presence: true
  validates :name, presence: true

  # Worker Web用の認証メソッド
  def authenticate_with_password(password)
    if encrypted_password.present?
      BCrypt::Password.new(encrypted_password) == password
    else
      birth_date.present? && password == birth_date.strftime("%m%d")
    end
  end

  def total_paid_leave_remaining
    paid_leave_grants.active.with_remaining.sum(:remaining_days)
  end
end
