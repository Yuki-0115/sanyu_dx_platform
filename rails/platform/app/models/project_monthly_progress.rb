# frozen_string_literal: true

# 案件ごとの月次出来高（累計）
class ProjectMonthlyProgress < ApplicationRecord
  belongs_to :project

  # Validations
  validates :year, presence: true, numericality: { greater_than: 2000 }
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :progress_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :project_id, uniqueness: { scope: [:year, :month], message: "この月の出来高は既に登録されています" }

  # Scopes
  scope :for_month, ->(year, month) { where(year: year, month: month) }
  scope :ordered, -> { order(:project_id) }

  # 出来高率（受注額に対する割合）
  def progress_rate
    return 0 unless project&.order_amount&.positive?
    ((progress_amount.to_d / project.order_amount) * 100).round(1)
  end

  # 前月の出来高
  def previous_progress
    prev_date = Date.new(year, month, 1).prev_month
    ProjectMonthlyProgress.find_by(project_id: project_id, year: prev_date.year, month: prev_date.month)
  end

  # 当月出来高（累計 - 前月累計）
  def monthly_progress_amount
    prev = previous_progress&.progress_amount || 0
    progress_amount - prev
  end

  # Class methods
  class << self
    # 指定月の全案件出来高合計
    def total_for_month(year, month)
      for_month(year, month).sum(:progress_amount).to_i
    end

    # 指定月の当月出来高合計（累計ではなく当月分）
    def monthly_total_for_month(year, month)
      for_month(year, month).includes(:project).sum do |p|
        p.monthly_progress_amount
      end
    end

    # 指定月に出来高が入力済みか
    def exists_for_month?(year, month)
      for_month(year, month).exists?
    end
  end
end
