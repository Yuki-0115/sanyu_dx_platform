# frozen_string_literal: true

class MonthlyReportsController < ApplicationController
  before_action :authenticate_user!

  def index
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month
    @available_months = available_months
  end

  def generate
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    unless GoogleDriveService.enabled?
      redirect_to monthly_reports_path(year: year, month: month),
                  alert: "Google Drive連携が設定されていません"
      return
    end

    result = MonthlyReportGenerator.generate_all(year: year, month: month)

    if result[:success]
      redirect_to monthly_reports_path(year: year, month: month),
                  notice: "月次帳票を生成しました。Google Driveで確認できます。"
    else
      redirect_to monthly_reports_path(year: year, month: month),
                  alert: "生成に失敗しました: #{result[:error]}"
    end
  end

  # CSVダウンロード（ローカル用）
  def download_cost_report
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    csv_data = MonthlyReportGenerator.generate_cost_report(year: year, month: month)
    send_csv(csv_data, "原価集計_#{year}#{month.to_s.rjust(2, '0')}.csv")
  end

  def download_profit_report
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    csv_data = MonthlyReportGenerator.generate_profit_report(year: year, month: month)
    send_csv(csv_data, "案件別利益_#{year}#{month.to_s.rjust(2, '0')}.csv")
  end

  def download_expense_report
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i || Date.current.month

    csv_data = MonthlyReportGenerator.generate_expense_report(year: year, month: month)
    send_csv(csv_data, "経費精算_#{year}#{month.to_s.rjust(2, '0')}.csv")
  end

  private

  def available_months
    # 過去12ヶ月分
    (0..11).map do |i|
      date = Date.current.beginning_of_month - i.months
      { year: date.year, month: date.month, label: "#{date.year}年#{date.month}月" }
    end
  end

  def send_csv(csv_data, filename)
    send_data "\xEF\xBB\xBF" + csv_data,
              filename: filename,
              type: "text/csv; charset=utf-8",
              disposition: "attachment"
  end
end
