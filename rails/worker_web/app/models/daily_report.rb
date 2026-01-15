# frozen_string_literal: true

class DailyReport < ApplicationRecord
  belongs_to :project

  has_many :attendances
end
