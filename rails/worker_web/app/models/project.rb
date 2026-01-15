# frozen_string_literal: true

class Project < ApplicationRecord
  belongs_to :client, optional: true

  has_many :daily_reports
end
