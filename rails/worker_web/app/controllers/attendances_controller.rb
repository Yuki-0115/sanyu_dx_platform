# frozen_string_literal: true

class AttendancesController < ApplicationController
  def index
    @year_month = params[:year_month] || Date.current.strftime("%Y-%m")
    year, month = @year_month.split("-").map(&:to_i)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    @attendances = current_worker.attendances
                                  .includes(daily_report: :project)
                                  .joins(:daily_report)
                                  .where(daily_reports: { report_date: start_date..end_date })
                                  .order("daily_reports.report_date DESC")

    @total_days = @attendances.count
    @total_hours = @attendances.sum(:hours_worked)
  end
end
