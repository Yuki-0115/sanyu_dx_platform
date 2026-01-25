# frozen_string_literal: true

# 販売費及び一般管理費（販管費）
# 第1層の月次損益計算書で使用
class MonthlyAdminExpense < ApplicationRecord
  # デフォルトカテゴリ一覧
  CATEGORIES = {
    "executive_salary" => "役員報酬",
    "office_salary" => "事務員給与",
    "office_rent" => "事務所家賃",
    "communication" => "通信費",
    "utility" => "水道光熱費",
    "depreciation" => "減価償却費",
    "other" => "その他"
  }.freeze

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :category, presence: true
  validates :name, presence: true
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

  # === クラスメソッド ===

  # 指定月の販管費合計
  def self.total_for_month(year, month)
    for_month(year, month).sum(:amount).to_i
  end

  # 指定月の販管費をカテゴリ別に集計
  def self.by_category_for_month(year, month)
    for_month(year, month)
      .group(:category)
      .sum(:amount)
      .transform_values(&:to_i)
  end

  # 指定月にデータが存在するか
  def self.exists_for_month?(year, month)
    for_month(year, month).exists?
  end

  # 前月からコピー
  def self.copy_from_previous_month(year, month)
    prev_year, prev_month = if month == 1
                              [year - 1, 12]
                            else
                              [year, month - 1]
                            end

    copied_count = 0
    for_month(prev_year, prev_month).find_each do |expense|
      create!(
        year: year,
        month: month,
        category: expense.category,
        name: expense.name,
        amount: expense.amount,
        description: expense.description
      )
      copied_count += 1
    end
    copied_count
  end

  # 利用可能なカテゴリ一覧（デフォルト＋カスタム）
  def self.available_categories(year = nil, month = nil)
    categories = CATEGORIES.dup
    if year && month
      # その月のカスタムカテゴリも追加
      for_month(year, month).distinct.pluck(:category).each do |cat|
        categories[cat] ||= cat unless CATEGORIES.key?(cat)
      end
    end
    categories
  end
end
