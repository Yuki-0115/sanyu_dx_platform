# frozen_string_literal: true

class PaidLeavesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_management_or_accounting!
  before_action :set_employee, only: [:show, :grant]

  def index
    @employees = Employee.where(employment_type: "regular")
                         .includes(:paid_leave_grants, :paid_leave_requests)
                         .order(:name)

    @summary = calculate_summary(@employees)
    @pending_requests_count = PaidLeaveRequest.pending.count
  end

  def show
    @grants = @employee.paid_leave_grants.order(grant_date: :desc)
    @requests = @employee.paid_leave_requests.includes(:approved_by).order(leave_date: :desc)
    @obligation = @employee.paid_leave_obligation_status
    @service = PaidLeaveGrantService.new(@employee)
  end

  # 管理簿CSV出力
  def report
    @year = params[:year]&.to_i || Date.current.year

    employees = Employee.where(employment_type: "regular")
                        .includes(:paid_leave_grants, :paid_leave_requests)

    respond_to do |format|
      format.csv do
        csv_data = PaidLeaveReportService.generate_csv(employees, @year)
        send_data csv_data,
                  filename: "有給休暇管理簿_#{@year}年度.csv",
                  type: "text/csv; charset=shift_jis"
      end
      format.html do
        @employees = employees
        render :report
      end
    end
  end

  # 一括付与
  def bulk_grant
    results = PaidLeaveGrantService.bulk_grant!

    if results[:granted].any?
      flash[:notice] = "#{results[:granted].size}名に有給を付与しました"
    else
      flash[:alert] = "付与対象者がいませんでした"
    end

    if results[:errors].any?
      flash[:alert] = "エラー: #{results[:errors].map { |e| "#{e[:employee].name}: #{e[:error]}" }.join(', ')}"
    end

    redirect_to paid_leaves_path
  end

  # 個別手動付与
  def grant
    service = PaidLeaveGrantService.new(@employee)
    days = params[:days].to_f
    grant_type = params[:grant_type] || "manual"
    notes = params[:notes]

    if days <= 0
      redirect_to paid_leave_path(@employee), alert: "付与日数を正しく入力してください"
      return
    end

    begin
      grant = service.manual_grant!(
        days: days,
        grant_type: grant_type,
        notes: notes
      )
      redirect_to paid_leave_path(@employee), notice: "#{days}日を付与しました"
    rescue => e
      redirect_to paid_leave_path(@employee), alert: e.message
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def require_management_or_accounting!
    unless current_user.role.in?(%w[admin management accounting])
      redirect_to root_path, alert: "アクセス権限がありません"
    end
  end

  def calculate_summary(employees)
    obligation_met = 0
    at_risk = 0

    employees.each do |emp|
      status = emp.paid_leave_obligation_status
      next if status[:status] == :not_applicable

      obligation_met += 1 if status[:taken] >= 5.0
      at_risk += 1 if status[:alert_level].in?(%i[warning danger urgent])
    end

    {
      total_employees: employees.count,
      obligation_met: obligation_met,
      at_risk: at_risk
    }
  end
end
