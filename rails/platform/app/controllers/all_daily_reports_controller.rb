# frozen_string_literal: true

class AllDailyReportsController < ApplicationController
  before_action :authorize_daily_reports_access

  def index
    @daily_reports = DailyReport.includes(:project, :foreman)
                                .order(report_date: :desc)
                                .limit(100)

    @draft_count = DailyReport.where(status: "draft").count
    @confirmed_count = DailyReport.where(status: "confirmed").count
  end

  private

  def authorize_daily_reports_access
    authorize_feature!(:daily_reports)
  end
end
