# frozen_string_literal: true

class MonthlySalary < ApplicationRecord
  belongs_to :employee

  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000 }
  validates :month, presence: true, numericality: { only_integer: true, in: 1..12 }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :employee_id, uniqueness: { scope: [:year, :month], message: "の給与は既に登録されています" }

  scope :for_month, ->(year, month) { where(year: year, month: month) }
  scope :for_regular_employees, -> { joins(:employee).where(employees: { employment_type: "regular" }) }

  def period_label
    "#{year}年#{month}月"
  end

  # クラスメソッド：指定月の正社員給与合計
  def self.total_for_month(year, month)
    for_month(year, month).for_regular_employees.sum(:total_amount).to_i
  end

  # クラスメソッド：指定月に確定給与が入力済みか
  def self.confirmed_for_month?(year, month)
    for_month(year, month).for_regular_employees.exists?
  end
end
