# frozen_string_literal: true

class MonthlySalariesController < ApplicationController
  before_action :set_period

  def index
    @regular_employees = Employee.where(employment_type: "regular").order(:name)
    @salaries = MonthlySalary.for_month(@year, @month).index_by(&:employee_id)
    @total = MonthlySalary.total_for_month(@year, @month)
    @is_confirmed = MonthlySalary.confirmed_for_month?(@year, @month)
  end

  def bulk_update
    success_count = 0
    error_messages = []

    params[:salaries]&.each do |employee_id, salary_params|
      amount = normalize_number(salary_params[:total_amount])
      next if amount.zero? && salary_params[:total_amount].blank?

      salary = MonthlySalary.find_or_initialize_by(
        employee_id: employee_id,
        year: @year,
        month: @month
      )

      if amount.zero?
        # 金額が0の場合は削除
        salary.destroy if salary.persisted?
      else
        salary.total_amount = amount
        salary.note = salary_params[:note]
        if salary.save
          success_count += 1
        else
          employee = Employee.find(employee_id)
          error_messages << "#{employee.name}: #{salary.errors.full_messages.join(', ')}"
        end
      end
    end

    if error_messages.any?
      redirect_to monthly_salaries_path(year: @year, month: @month), alert: "一部エラーがあります: #{error_messages.join('; ')}"
    else
      redirect_to monthly_salaries_path(year: @year, month: @month), notice: "#{@year}年#{@month}月の給与を保存しました"
    end
  end

  private

  def set_period
    @year = params[:year].to_i
    @month = params[:month].to_i

    if @year < 2000 || @month < 1 || @month > 12
      redirect_to monthly_salaries_path(year: Date.current.year, month: Date.current.month)
    end
  end
end
