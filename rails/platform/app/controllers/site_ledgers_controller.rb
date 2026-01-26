# frozen_string_literal: true

class SiteLedgersController < ApplicationController
  authorize_with :projects
  before_action :set_project

  def show
    @budget = @project.budget
    @daily_reports = @project.confirmed_daily_reports
                             .includes(:attendances, :outsourcing_entries, :expenses)
                             .order(report_date: :desc)

    # 日別集計データ（日報の直接入力値を使用）
    @daily_summary = build_daily_summary
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def build_daily_summary
    @daily_reports.map do |report|
      # 正社員の人工数（勤怠管理用）
      regular_days = 0.to_d
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

      # 外注人工数（参考情報）
      outsourcing_man_days = report.outsourcing_entries
                                   .select(&:man_days_billing?)
                                   .sum { |o| o.man_days }.to_d

      {
        report: report,
        date: report.report_date,
        # 人工数（勤怠管理用）
        regular_days: regular_days,
        temporary_days: temporary_days,
        outsourcing_man_days: outsourcing_man_days,
        # 原価情報（日報の直接入力値）
        labor_cost: report.labor_cost.to_i,
        material_cost: report.material_cost.to_i,
        outsourcing_cost: report.outsourcing_cost.to_i,
        transportation_cost: report.transportation_cost.to_i,
        # ガソリン・高速代
        fuel_cost: report.fuel_amount.to_i,
        highway_cost: report.highway_amount.to_i
      }
    end
  end
end
