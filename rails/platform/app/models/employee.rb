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
      management: %i[dashboard projects estimates budgets daily_reports invoices offsets accounting safety_documents master],
      accounting: %i[dashboard invoices payments offsets expenses accounting master],
      sales: %i[dashboard projects estimates clients master],
      engineering: %i[dashboard projects budgets daily_reports safety_documents],
      construction: %i[dashboard projects daily_reports attendances expenses safety_documents],
      worker: %i[daily_reports attendances]
    }

    allowed = permissions[role.to_sym]
    return true if allowed == :all

    allowed&.include?(feature.to_sym)
  end

  private

  def generate_code
    return if code.present?

    prefix = "EMP"
    date_part = Date.current.strftime("%Y%m")
    seq = Employee.where("code LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.code = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end
end
