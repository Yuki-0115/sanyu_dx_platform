# frozen_string_literal: true

class Partner < ApplicationRecord
  has_many :workers, foreign_key: :partner_id
  has_many :outsourcing_schedules
  has_many :outsourcing_entries
end
