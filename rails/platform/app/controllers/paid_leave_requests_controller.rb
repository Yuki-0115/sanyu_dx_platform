# frozen_string_literal: true

class PaidLeaveRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_request, only: [:approve, :reject, :cancel]

  def index
    @requests = if can_approve?
                  PaidLeaveRequest.includes(:employee, :approved_by)
                                  .order(created_at: :desc)
                else
                  current_user.paid_leave_requests
                              .includes(:approved_by)
                              .order(created_at: :desc)
                end

    @pending_requests = @requests.pending if can_approve?
  end

  def new
    @request = current_user.paid_leave_requests.build
    @remaining_days = current_user.total_paid_leave_remaining
    @obligation = current_user.paid_leave_obligation_status
  end

  def create
    @request = current_user.paid_leave_requests.build(request_params)

    if @request.save
      redirect_to paid_leave_requests_path, notice: "有給申請を提出しました"
    else
      @remaining_days = current_user.total_paid_leave_remaining
      @obligation = current_user.paid_leave_obligation_status
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    unless can_approve?
      redirect_to paid_leave_requests_path, alert: "承認権限がありません"
      return
    end

    begin
      @request.approve!(current_user)
      redirect_to paid_leave_requests_path, notice: "承認しました"
    rescue => e
      redirect_to paid_leave_requests_path, alert: e.message
    end
  end

  def reject
    unless can_approve?
      redirect_to paid_leave_requests_path, alert: "承認権限がありません"
      return
    end

    reason = params[:rejection_reason]

    if reason.blank?
      redirect_to paid_leave_requests_path, alert: "却下理由を入力してください"
      return
    end

    @request.reject!(current_user, reason)
    redirect_to paid_leave_requests_path, notice: "却下しました"
  end

  def cancel
    unless @request.employee_id == current_user.id
      redirect_to paid_leave_requests_path, alert: "自分の申請のみキャンセルできます"
      return
    end

    unless @request.pending?
      redirect_to paid_leave_requests_path, alert: "承認待ち以外の申請はキャンセルできません"
      return
    end

    @request.cancel!
    redirect_to paid_leave_requests_path, notice: "申請をキャンセルしました"
  end

  private

  def set_request
    @request = PaidLeaveRequest.find(params[:id])
  end

  def request_params
    params.require(:paid_leave_request).permit(:leave_date, :leave_type, :reason)
  end

  def can_approve?
    current_user.role.in?(%w[admin management engineering construction])
  end
  helper_method :can_approve?
end
