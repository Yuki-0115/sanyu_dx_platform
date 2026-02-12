# frozen_string_literal: true

class OutsourcingEntry < ApplicationRecord
  ATTENDANCE_TYPES = %w[full half].freeze
  BILLING_TYPES = %w[man_days contract].freeze
  UNITS = %w[m m2 m3 式 本 枚 個 台 人 日 回 t kg].freeze

  belongs_to :daily_report
  belongs_to :partner, optional: true

  validates :headcount, presence: true, numericality: { greater_than: 0 }, if: -> { billing_type == "man_days" }
  validates :attendance_type, presence: true, inclusion: { in: ATTENDANCE_TYPES }, if: -> { billing_type == "man_days" }
  validates :quantity, presence: true, numericality: { greater_than: 0 }, if: -> { billing_type == "contract" }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }, if: -> { billing_type == "contract" }

  before_validation :calculate_contract_amount, if: -> { billing_type == "contract" }

  def company_name
    partner&.name || partner_name
  end

  private

  def calculate_contract_amount
    if quantity.present? && unit_price.present?
      self.contract_amount = (quantity * unit_price).round(0)
    end
  end
end
