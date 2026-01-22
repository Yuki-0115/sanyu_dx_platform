# frozen_string_literal: true

class EstimateConfirmation < ApplicationRecord
  # Associations
  belongs_to :estimate

  # Validations
  validates :item_name, presence: true

  # Defaults
  attribute :sort_order, :integer, default: 0

  # responsibility の値
  # - 'client': 貴社
  # - 'company': 当社
  # - nil: 未選択
  RESPONSIBILITIES = %w[client company].freeze

  def client_responsible?
    responsibility == "client"
  end

  def company_responsible?
    responsibility == "company"
  end
end
