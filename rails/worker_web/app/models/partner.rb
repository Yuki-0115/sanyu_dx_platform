# frozen_string_literal: true

class Partner < ApplicationRecord
  belongs_to :tenant, optional: true

  has_many :workers
end
