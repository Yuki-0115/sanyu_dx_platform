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
      # 社員区分別の人工数を計算
      regular_days = 0.to_d
      temporary_days = 0.to_d
      external_days = 0.to_d

      report.attendances.includes(:employee).each do |attendance|
        days = attendance.man_days
        if attendance.employee.nil?
          external_days += days
        else
          case attendance.employee.employment_type
          when "regular"
            regular_days += days
          when "temporary"
            temporary_days += days
          when "external"
            external_days += days
          end
        end
      end

      outsourcing_days = report.outsourcing_entries.sum { |o| o.man_days }

      # 単価を取得
      regular_unit = @project.regular_labor_unit_price
      temporary_unit = @project.temporary_labor_unit_price
      outsourcing_unit = @project.outsourcing_unit_price

      # 労務費を計算
      regular_labor_cost = (regular_unit * regular_days).round(0)
      temporary_labor_cost = (temporary_unit * temporary_days).round(0)
      external_labor_cost = (outsourcing_unit * external_days).round(0)
      total_labor_cost = regular_labor_cost + temporary_labor_cost + external_labor_cost

      {
        report: report,
        date: report.report_date,
        regular_days: regular_days,
        temporary_days: temporary_days,
        external_days: external_days,
        outsourcing_days: outsourcing_days,
        total_man_days: regular_days + temporary_days + external_days,
        regular_labor_cost: regular_labor_cost,
        temporary_labor_cost: temporary_labor_cost,
        external_labor_cost: external_labor_cost,
        labor_cost: total_labor_cost,
        outsourcing_cost: (outsourcing_unit * outsourcing_days).round(0),
        material_cost: report.expenses.where(category: "material", status: "approved").sum(:amount).to_i,
        expense_cost: report.expenses.where.not(category: "material").where(status: "approved").sum(:amount).to_i
      }
    end
  end
end
