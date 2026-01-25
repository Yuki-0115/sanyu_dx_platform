# frozen_string_literal: true

class MonthlyOutsourcingCostsController < ApplicationController
  before_action :set_period

  def index
    @partners = Partner.order(:name)

    # その月の確定外注費データ
    @outsourcing_costs = MonthlyOutsourcingCost.for_month(@year, @month)
                                               .includes(:partner, :project)
                                               .index_by { |c| [c.partner_id, c.project_id] }

    # その月の日報ベース外注費（概算参考値）
    @estimated_costs = build_estimated_costs(@year, @month)

    # 対象案件: アクティブな案件 + 概算データがある案件
    active_project_ids = Project.where(status: %w[ordered preparing in_progress]).pluck(:id)
    estimated_project_ids = @estimated_costs.keys.map { |k| k[1] }.uniq
    confirmed_project_ids = @outsourcing_costs.keys.map { |k| k[1] }.uniq
    all_project_ids = (active_project_ids + estimated_project_ids + confirmed_project_ids).uniq
    @active_projects = Project.where(id: all_project_ids).order(:name)

    @total = MonthlyOutsourcingCost.total_for_month(@year, @month)
    @is_confirmed = MonthlyOutsourcingCost.confirmed_for_month?(@year, @month)
    @totals_by_partner = MonthlyOutsourcingCost.totals_by_partner_for_month(@year, @month)
  end

  # 個別確定
  def confirm_single
    partner_id = params[:partner_id].to_i
    project_id = params[:project_id].to_i
    amount = normalize_number(params[:amount])
    note = params[:note]

    @partner = Partner.find(partner_id)
    @project = Project.find(project_id)
    @estimated = build_estimated_costs(@year, @month)[[partner_id, project_id]]

    if amount.zero?
      # 金額0の場合は削除（確定解除）
      cost = MonthlyOutsourcingCost.find_by(
        partner_id: partner_id,
        project_id: project_id,
        year: @year,
        month: @month
      )
      cost&.destroy
      @cost = nil
      @message = "確定を解除しました"
    else
      @cost = MonthlyOutsourcingCost.find_or_initialize_by(
        partner_id: partner_id,
        project_id: project_id,
        year: @year,
        month: @month
      )
      @cost.amount = amount
      @cost.note = note

      if @cost.save
        @message = "確定しました"
      else
        @error = @cost.errors.full_messages.join(", ")
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to monthly_outsourcing_costs_path(year: @year, month: @month) }
    end
  end

  # 確定解除
  def unconfirm_single
    partner_id = params[:partner_id].to_i
    project_id = params[:project_id].to_i

    @partner = Partner.find(partner_id)
    @project = Project.find(project_id)
    @estimated = build_estimated_costs(@year, @month)[[partner_id, project_id]]

    cost = MonthlyOutsourcingCost.find_by(
      partner_id: partner_id,
      project_id: project_id,
      year: @year,
      month: @month
    )
    cost&.destroy
    @cost = nil

    respond_to do |format|
      format.turbo_stream { render :confirm_single }
      format.html { redirect_to monthly_outsourcing_costs_path(year: @year, month: @month) }
    end
  end

  private

  helper_method :build_partner_estimated_total

  def build_partner_estimated_total(partner_id)
    build_estimated_costs(@year, @month)
      .select { |k, _| k[0] == partner_id }
      .values
      .sum { |v| v[:total] }
  end

  def set_period
    @year = params[:year].to_i
    @month = params[:month].to_i

    if @year < 2000 || @month < 1 || @month > 12
      redirect_to monthly_outsourcing_costs_path(year: Date.current.year, month: Date.current.month)
    end
  end

  # 日報ベースの外注費（参考値）
  def build_estimated_costs(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    costs = {}

    OutsourcingEntry.joins(:daily_report)
                    .where(daily_reports: { report_date: start_date..end_date, status: %w[confirmed revised] })
                    .includes(:partner, daily_report: :project)
                    .find_each do |entry|
      project = entry.daily_report.project
      next unless project && entry.partner_id

      key = [entry.partner_id, project.id]
      costs[key] ||= { man_days: 0, contract: 0 }

      if entry.billing_type == "man_days"
        days = entry.attendance_type == "full" ? entry.headcount : entry.headcount * 0.5
        costs[key][:man_days] += (project.outsourcing_unit_price * days).round(0)
      else
        costs[key][:contract] += entry.contract_amount.to_i
      end
    end

    # totalを計算
    costs.transform_values { |v| v.merge(total: v[:man_days] + v[:contract]) }
  end
end
