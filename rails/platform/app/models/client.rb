# frozen_string_literal: true

class Client < ApplicationRecord
  include Auditable

  # Associations
  has_many :projects, dependent: :restrict_with_error

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
