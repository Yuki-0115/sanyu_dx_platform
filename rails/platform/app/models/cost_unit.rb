# frozen_string_literal: true

class CostUnit < ApplicationRecord
  # デフォルトの単位（初期データ用）
  DEFAULT_UNITS = %w[式 m m² m³ t kg 本 個 台 人工 日 回 箇所 セット].freeze

  # Validations
  validates :name, presence: true, uniqueness: true

  # Scopes
  scope :ordered, -> { order(:sort_order, :name) }

  # 全単位を配列で取得（DBに登録がなければデフォルト値を返す）
  def self.all_names
    if any?
      ordered.pluck(:name)
    else
      DEFAULT_UNITS
    end
  end
end
