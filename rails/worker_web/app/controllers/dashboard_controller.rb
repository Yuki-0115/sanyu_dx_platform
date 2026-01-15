# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @worker = current_worker
    @recent_attendances = current_worker.attendances
                                        .includes(daily_report: :project)
                                        .order("daily_reports.report_date DESC")
                                        .limit(10)

    # 今月の出勤日数
    @current_month_attendance = current_worker.attendances
                                               .joins(:daily_report)
                                               .where(daily_reports: {
                                                 report_date: Date.current.beginning_of_month..Date.current.end_of_month
                                               })
                                               .count

    # 今月の総労働時間
    @current_month_hours = current_worker.attendances
                                          .joins(:daily_report)
                                          .where(daily_reports: {
                                            report_date: Date.current.beginning_of_month..Date.current.end_of_month
                                          })
                                          .sum(:hours_worked)
  end
end
