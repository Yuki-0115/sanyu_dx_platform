# frozen_string_literal: true

class Client < ApplicationRecord
  include Auditable

  # Associations
  has_many :projects, dependent: :restrict_with_error

  # Validations
  validates :code, uniqueness: true
  validates :name, presence: true

  # Callbacks
  before_validation :generate_code, on: :create

  private

  def generate_code
    return if code.present?

    prefix = "CL"
    date_part = Date.current.strftime("%Y%m")
    seq = Client.where("code LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.code = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end
end
