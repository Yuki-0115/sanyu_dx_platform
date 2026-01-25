# frozen_string_literal: true

class MonthlyFixedCost < ApplicationRecord
  # カテゴリ一覧
  CATEGORIES = {
    "depreciation" => "減価償却",
    "vehicle" => "車両費",
    "insurance" => "保険料",
    "rental" => "リース・レンタル",
    "utility" => "水道光熱費",
    "office" => "事務所費",
    "salary_overhead" => "給与関連経費",
    "other" => "その他"
  }.freeze

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES.keys }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :for_month, ->(year, month) { where(year: year, month: month) }
  scope :by_category, ->(category) { where(category: category) }
  scope :ordered, -> { order(:category, :name) }

  def category_name
    CATEGORIES[category] || category
  end

  def period_label
    "#{year}年#{month}月"
  end

  # クラスメソッド：指定月の固定費合計
  def self.total_for_month(year, month)
    for_month(year, month).sum(:amount).to_i
  end

  # クラスメソッド：指定月の固定費をカテゴリ別に集計
  def self.by_category_for_month(year, month)
    for_month(year, month).group(:category).sum(:amount).transform_values(&:to_i)
  end

  # クラスメソッド：前月からコピー
  def self.copy_from_previous_month(year, month)
    prev_year, prev_month = if month == 1
                              [year - 1, 12]
                            else
                              [year, month - 1]
                            end

    for_month(prev_year, prev_month).find_each do |cost|
      create!(
        year: year,
        month: month,
        name: cost.name,
        category: cost.category,
        amount: cost.amount,
        description: cost.description
      )
    end
  end
end
