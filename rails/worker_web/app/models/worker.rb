# frozen_string_literal: true

class Worker < ApplicationRecord
  belongs_to :partner, optional: true

  has_many :attendances

  validates :code, presence: true
  validates :name, presence: true
end
