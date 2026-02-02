# frozen_string_literal: true

class Partner < ApplicationRecord
  include Auditable

  # Associations
  has_many :employees, dependent: :nullify
  has_many :offsets, dependent: :restrict_with_error
  has_many :payment_terms, as: :termable, dependent: :destroy
  has_many :cash_flow_entries, dependent: :nullify

  # Validations
  validates :code, uniqueness: true
  validates :name, presence: true

  # Callbacks
  before_validation :generate_code, on: :create

  # Defaults
  attribute :has_temporary_employees, :boolean, default: false
  attribute :carryover_balance, :decimal, default: 0

  # デフォルト支払サイト
  def default_payment_term
    payment_terms.default_term.first || payment_terms.first
  end

  private

  def generate_code
    return if code.present?

    prefix = "PT"
    date_part = Date.current.strftime("%Y%m")
    seq = Partner.where("code LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.code = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end
end
