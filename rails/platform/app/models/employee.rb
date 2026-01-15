# frozen_string_literal: true

class Employee < ApplicationRecord
  include TenantScoped
  include Auditable

  # Constants
  EMPLOYMENT_TYPES = %w[regular temporary].freeze
  ROLES = %w[admin management accounting sales engineering construction worker].freeze

  # Associations
  belongs_to :partner, optional: true

  has_many :daily_reports_as_foreman, class_name: "DailyReport", foreign_key: :foreman_id,
                                      dependent: :restrict_with_error, inverse_of: :foreman
  has_many :attendances, dependent: :restrict_with_error
  has_many :expenses_as_payer, class_name: "Expense", foreign_key: :payer_id,
                               dependent: :restrict_with_error, inverse_of: :payer

  # Validations
  validates :code, presence: true, uniqueness: { scope: :tenant_id }
  validates :name, presence: true
  validates :employment_type, presence: true, inclusion: { in: EMPLOYMENT_TYPES }
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :email, uniqueness: { scope: :tenant_id }, allow_blank: true

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
end
