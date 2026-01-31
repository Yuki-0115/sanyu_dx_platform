# frozen_string_literal: true

class OutsourcingReportsController < ApplicationController
  include ProjectScoped

  def index
    @outsourcing_entries = OutsourcingEntry
      .joins(:daily_report)
      .where(daily_reports: { project_id: @project.id, status: %w[confirmed revised] })
      .includes(:partner, daily_report: :foreman)
      .order("daily_reports.report_date DESC")

    # 会社別集計
    @summary_by_company = @outsourcing_entries
      .group_by(&:company_name)
      .transform_values do |entries|
        {
          man_days: entries.select(&:man_days_billing?).sum(&:man_days),
          contract_amount: entries.select(&:contract_billing?).sum { |e| e.contract_amount.to_i },
          entries_count: entries.size
        }
      end
      .sort_by { |_name, data| -data[:man_days] }
  end

  def new
    @daily_report = @project.daily_reports.build(
      report_date: Date.current,
      foreman: current_employee
    )
    @daily_report.outsourcing_entries.build
  end

  def create
    @daily_report = @project.daily_reports.build(daily_report_params)
    @daily_report.foreman = current_employee
    @daily_report.status = "confirmed"

    if @daily_report.save
      redirect_to project_outsourcing_reports_path(@project),
                  notice: "外注報告を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def daily_report_params
    params.require(:daily_report).permit(
      :report_date,
      :outsourcing_cost,
      :outsourcing_details,
      outsourcing_entries_attributes: %i[
        id partner_id partner_name billing_type
        headcount attendance_type contract_amount
        quantity unit work_description _destroy
      ]
    )
  end
end
