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
      man_days = report.attendances.sum { |a| a.man_days }
      outsourcing_days = report.outsourcing_entries.sum { |o| o.man_days }
      unit_price = @project.labor_unit_price

      {
        report: report,
        date: report.report_date,
        man_days: man_days,
        outsourcing_days: outsourcing_days,
        labor_cost: (unit_price * man_days).round(0),
        outsourcing_cost: (unit_price * outsourcing_days).round(0),
        material_cost: report.expenses.where(category: "material", status: "approved").sum(:amount).to_i,
        expense_cost: report.expenses.where.not(category: "material").where(status: "approved").sum(:amount).to_i
      }
    end
  end
end
