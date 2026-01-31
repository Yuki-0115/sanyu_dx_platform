# frozen_string_literal: true

# 月次データを扱うモデルの共通スコープとメソッド
module MonthlyScoped
  extend ActiveSupport::Concern

  included do
    scope :for_month, ->(year, month) { where(year: year, month: month) }
    scope :for_year, ->(year) { where(year: year) }
    scope :ordered_by_period, -> { order(year: :desc, month: :desc) }
  end

  # 期間ラベル（例: "2026年1月"）
  def period_label
    "#{year}年#{month}月"
  end

  # 期間キー（例: "2026-01"）
  def period_key
    format("%<year>04d-%<month>02d", year: year, month: month)
  end

  class_methods do
    # 前月からデータをコピー
    def copy_from_previous_month(year, month, &block)
      prev_year, prev_month = if month == 1
        [year - 1, 12]
      else
        [year, month - 1]
      end

      copied_count = 0
      for_month(prev_year, prev_month).find_each do |record|
        new_attrs = block ? block.call(record) : {}
        new_record = record.dup
        new_record.assign_attributes(year: year, month: month, **new_attrs)
        new_record.save!
        copied_count += 1
      end
      copied_count
    end

    # 月次集計
    def total_for_month(year, month, column = :amount)
      for_month(year, month).sum(column)
    end
  end
end
