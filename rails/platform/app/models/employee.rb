# frozen_string_literal: true

class Employee < ApplicationRecord
  include Auditable

  # Devise modules
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  # Constants
  EMPLOYMENT_TYPES = %w[regular temporary external].freeze
  ROLES = %w[admin management accounting sales engineering construction worker].freeze

  # Associations
  belongs_to :partner, optional: true

  has_many :project_assignments, dependent: :destroy
  has_many :projects, through: :project_assignments

  has_many :daily_reports_as_foreman, class_name: "DailyReport", foreign_key: :foreman_id,
                                      dependent: :restrict_with_error, inverse_of: :foreman
  has_many :attendances, dependent: :restrict_with_error
  has_many :expenses_as_payer, class_name: "Expense", foreign_key: :payer_id,
                               dependent: :restrict_with_error, inverse_of: :payer

  # 有給休暇管理
  has_many :paid_leave_grants, dependent: :destroy
  has_many :paid_leave_requests, dependent: :destroy

  # Validations
  validates :code, uniqueness: true
  validates :name, presence: true
  validates :employment_type, presence: true, inclusion: { in: EMPLOYMENT_TYPES }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :email, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_code, on: :create

  # Scopes
  scope :regular, -> { where(employment_type: "regular") }
  scope :temporary, -> { where(employment_type: "temporary") }

  # Instance methods
  def regular?
    employment_type == "regular"
  end

  def temporary?
    employment_type == "temporary"
  end

  def admin?
    role == "admin"
  end

  def management?
    role == "management"
  end

  # Role check methods
  ROLES.each do |r|
    define_method("#{r}?") { role == r } unless method_defined?("#{r}?")
  end

  # Check if user can access a feature based on role
  def can_access?(feature)
    permissions = {
      admin: :all,
      management: %i[dashboard management_dashboard projects estimates budgets daily_reports invoices offsets accounting safety_documents master schedule attendance_sheets cash_flow paid_leaves paid_leave_requests],
      accounting: %i[dashboard management_dashboard invoices payments offsets expenses accounting master cash_flow paid_leaves],
      sales: %i[dashboard projects estimates clients master schedule paid_leave_requests],
      engineering: %i[dashboard projects budgets daily_reports safety_documents schedule attendance_sheets paid_leave_requests],
      construction: %i[dashboard projects daily_reports attendances expenses safety_documents schedule paid_leave_requests],
      worker: %i[dashboard daily_reports attendances schedule paid_leave_requests]
    }

    allowed = permissions[role.to_sym]
    return true if allowed == :all

    allowed&.include?(feature.to_sym)
  end

  # Check if user can edit a feature (some features are read-only for certain roles)
  def can_edit?(feature)
    # Workers can only view schedule, not edit
    return false if worker? && feature.to_sym == :schedule

    can_access?(feature)
  end

  # =====================
  # 有給休暇関連メソッド
  # =====================

  # 有給残日数合計
  def total_paid_leave_remaining
    paid_leave_grants.active.with_remaining.sum(:remaining_days)
  end

  # 当期の取得日数
  def paid_leave_taken_in_period(start_date, end_date)
    paid_leave_requests
      .approved
      .for_period(start_date, end_date)
      .sum(:consumed_days)
  end

  # 年5日取得義務の達成状況
  def paid_leave_obligation_status
    base_date = paid_leave_base_date || (hire_date && (hire_date + 6.months))
    return { status: :not_applicable, message: "入社日未設定" } unless base_date

    period_start = calculate_current_period_start(base_date)
    period_end = period_start + 1.year - 1.day

    # 基準期間が未来の場合
    return { status: :not_applicable, message: "付与前" } if period_start > Date.current

    taken = paid_leave_taken_in_period(period_start, period_end)
    days_remaining_in_period = (period_end - Date.current).to_i
    months_elapsed = ((Date.current - period_start) / 30.0).floor

    {
      period_start: period_start,
      period_end: period_end,
      taken: taken,
      required: 5.0,
      shortage: [5.0 - taken, 0].max,
      days_remaining_in_period: [days_remaining_in_period, 0].max,
      alert_level: calculate_alert_level(taken, months_elapsed)
    }
  end

  # 次回付与予定日
  def next_paid_leave_grant_date
    base_date = paid_leave_base_date || (hire_date && (hire_date + 6.months))
    return nil unless base_date
    return base_date if base_date > Date.current

    years_since_base = ((Date.current - base_date) / 365.25).floor
    base_date + (years_since_base + 1).years
  end

  private

  def calculate_current_period_start(base_date)
    return base_date if base_date > Date.current

    # 基準日の月日を今年度に適用
    years_since_base = ((Date.current - base_date) / 365.25).floor
    current_period_start = base_date + years_since_base.years

    # まだ今年度の基準日に達していない場合は前年度
    current_period_start > Date.current ? current_period_start - 1.year : current_period_start
  end

  def calculate_alert_level(taken, months_elapsed)
    return :ok if taken >= 5.0
    return :urgent if months_elapsed >= 11 && taken < 5.0
    return :danger if months_elapsed >= 9 && taken < 3.0
    return :warning if months_elapsed >= 6 && taken < 2.0

    :normal
  end

  def generate_code
    return if code.present?

    prefix = "EMP"
    date_part = Date.current.strftime("%Y%m")
    seq = Employee.where("code LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.code = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end
end
