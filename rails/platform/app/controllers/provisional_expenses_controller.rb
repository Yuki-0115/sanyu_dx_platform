# frozen_string_literal: true

class ProvisionalExpensesController < ApplicationController
  authorize_with :accounting

  def index
    @year_month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    @date_range = @year_month.beginning_of_month..@year_month.end_of_month

    # 未確定の燃料費・高速代がある日報を取得
    @daily_reports = DailyReport.includes(:project, :foreman)
                                .where(report_date: @date_range)
                                .where(
                                  "(fuel_quantity > 0 AND fuel_confirmed = ?) OR (highway_count > 0 AND highway_confirmed = ?)",
                                  false, false
                                )
                                .order(report_date: :asc)

    # 集計
    @fuel_total = @daily_reports.where("fuel_quantity > 0 AND fuel_confirmed = ?", false).sum(:fuel_amount)
    @highway_total = @daily_reports.where("highway_count > 0 AND highway_confirmed = ?", false).sum(:highway_amount)
    @fuel_count = @daily_reports.where("fuel_quantity > 0 AND fuel_confirmed = ?", false).count
    @highway_count = @daily_reports.where("highway_count > 0 AND highway_confirmed = ?", false).count
  end

  def confirm_fuel
    @daily_report = DailyReport.find(params[:id])
    unit_price = params[:unit_price].to_d

    if @daily_report.confirm_fuel!(unit_price)
      confirmed_amount = @daily_report.fuel_confirmed_amount.to_i
      redirect_to provisional_expenses_path(month: @daily_report.report_date.strftime("%Y-%m")),
                  notice: "燃料費を確定しました（#{@daily_report.fuel_quantity}L × ¥#{unit_price}/L = ¥#{confirmed_amount.to_fs(:delimited)}）"
    else
      redirect_to provisional_expenses_path, alert: "確定に失敗しました"
    end
  end

  def confirm_highway
    @daily_report = DailyReport.find(params[:id])
    confirmed_amount = params[:confirmed_amount].to_d

    if @daily_report.confirm_highway!(confirmed_amount)
      redirect_to provisional_expenses_path(month: @daily_report.report_date.strftime("%Y-%m")),
                  notice: "高速代を確定しました（¥#{confirmed_amount.to_i.to_fs(:delimited)}）"
    else
      redirect_to provisional_expenses_path, alert: "確定に失敗しました"
    end
  end

  # 燃料費一括確定
  def bulk_confirm_fuel
    year_month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month
    date_range = year_month.beginning_of_month..year_month.end_of_month
    fuel_type = params[:fuel_type]
    unit_price = params[:unit_price].to_d

    # 対象の日報を取得
    scope = DailyReport.where(report_date: date_range)
                       .where("fuel_quantity > 0 AND fuel_confirmed = ?", false)
    scope = scope.where(fuel_type: fuel_type) if fuel_type.present?

    confirmed_count = 0
    total_quantity = 0
    total_amount = 0

    scope.find_each do |report|
      if report.confirm_fuel!(unit_price)
        confirmed_count += 1
        total_quantity += report.fuel_quantity
        total_amount += report.fuel_confirmed_amount
      end
    end

    if confirmed_count > 0
      redirect_to provisional_expenses_path(month: year_month.strftime("%Y-%m")),
                  notice: "#{confirmed_count}件の燃料費を一括確定しました（計#{total_quantity}L × ¥#{unit_price}/L = ¥#{total_amount.to_i.to_fs(:delimited)}）"
    else
      redirect_to provisional_expenses_path(month: year_month.strftime("%Y-%m")),
                  alert: "確定対象がありませんでした"
    end
  end

end
