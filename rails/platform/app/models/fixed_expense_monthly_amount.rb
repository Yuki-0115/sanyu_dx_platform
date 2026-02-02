# frozen_string_literal: true

class FixedExpenseMonthlyAmount < ApplicationRecord
  belongs_to :fixed_expense_schedule

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :fixed_expense_schedule_id, uniqueness: { scope: %i[year month], message: "この年月は既に登録されています" }

  # Callbacks - CashFlowEntryを自動更新
  after_save :update_cash_flow_entry
  after_destroy :reset_cash_flow_entry

  scope :for_month, ->(year, month) { where(year: year, month: month) }

  def month_label
    "#{year}年#{month}月"
  end

  private

  def update_cash_flow_entry
    fixed_expense_schedule.generate_cash_flow_entry_for(year, month)
  end

  def reset_cash_flow_entry
    # 削除時はスケジュールのデフォルト金額で再生成
    fixed_expense_schedule.generate_cash_flow_entry_for(year, month)
  end
end
