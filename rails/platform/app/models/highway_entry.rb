# frozen_string_literal: true

class HighwayEntry < ApplicationRecord
  belongs_to :daily_report
  has_one_attached :receipt

  validates :amount, numericality: { greater_than: 0 }, allow_nil: true
end
