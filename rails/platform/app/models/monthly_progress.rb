# frozen_string_literal: true

# 月次出来高（進捗）管理
# 案件ごとに月次の出来高金額を記録
# 仕掛かり = 累計出来高 - 累計請求額 で自動計算
# 原価は日報から集計（材料費などは備考に記載）
class MonthlyProgress < ApplicationRecord
  belongs_to :project

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :progress_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :project_id, uniqueness: { scope: [:year, :month], message: "の出来高は既に登録されています" }

  scope :for_month, ->(year, month) { where(year: year, month: month) }
  scope :for_project, ->(project_id) { where(project_id: project_id) }

  def period_label
    "#{year}年#{month}月"
  end

  # === クラスメソッド ===

  # 指定月の出来高合計
  def self.total_progress_for_month(year, month)
    for_month(year, month).sum(:progress_amount).to_i
  end

  # 案件の累計出来高
  def self.cumulative_progress_for_project(project_id)
    for_project(project_id).sum(:progress_amount).to_i
  end
end
