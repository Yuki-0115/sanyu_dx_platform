# frozen_string_literal: true

class SiteLedgersController < ApplicationController
  authorize_with :projects
  before_action :set_project

  def show
    @budget = @project.budget
    @daily_reports = @project.confirmed_daily_reports
                             .includes(:attendances, :outsourcing_entries, :expenses)
                             .order(report_date: :desc)

    # 日別集計データ
    @daily_summary = build_daily_summary
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def build_daily_summary
    @daily_reports.map do |report|
      # 正社員の人工数（労務費用）
      regular_days = 0.to_d
      # 仮社員の人工数（勤怠管理用、原価には含めない）
      temporary_days = 0.to_d

      report.attendances.includes(:employee).each do |attendance|
        days = attendance.man_days
        next if attendance.employee.nil?

        case attendance.employee.employment_type
        when "regular"
          regular_days += days
        when "temporary"
          temporary_days += days
        end
      end

      # 外注（人工）
      outsourcing_man_days_entries = report.outsourcing_entries.select(&:man_days_billing?)
      outsourcing_man_days = outsourcing_man_days_entries.sum { |o| o.man_days }.to_d

      # 外注（請負）
      outsourcing_contract_entries = report.outsourcing_entries.select(&:contract_billing?)
      outsourcing_contract_cost = outsourcing_contract_entries.sum { |o| o.contract_amount.to_i }

      # 単価を取得
      regular_unit = @project.regular_labor_unit_price
      outsourcing_unit = @project.outsourcing_unit_price

      # 労務費（正社員のみ）
      labor_cost = (regular_unit * regular_days).round(0)

      # 外注費（人工）
      outsourcing_man_days_cost = (outsourcing_unit * outsourcing_man_days).round(0)

      {
        report: report,
        date: report.report_date,
        regular_days: regular_days,
        temporary_days: temporary_days,
        outsourcing_man_days: outsourcing_man_days,
        labor_cost: labor_cost,
        outsourcing_man_days_cost: outsourcing_man_days_cost,
        outsourcing_contract_cost: outsourcing_contract_cost,
        outsourcing_cost: outsourcing_man_days_cost + outsourcing_contract_cost,
        material_cost: report.expenses.where(category: "material", status: "approved").sum(:amount).to_i,
        expense_cost: report.expenses.where.not(category: "material").where(status: "approved").sum(:amount).to_i
      }
    end
  end
end
