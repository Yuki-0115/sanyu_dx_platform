# frozen_string_literal: true

class PaidLeaveRequestsController < ApplicationController
  def index
    @requests = current_worker.paid_leave_requests.order(created_at: :desc)
    @remaining_days = current_worker.total_paid_leave_remaining
  end

  def new
    @request = current_worker.paid_leave_requests.build(leave_type: "full")
    @remaining_days = current_worker.total_paid_leave_remaining
  end

  def create
    @request = current_worker.paid_leave_requests.build(request_params)

    if @request.save
      redirect_to paid_leave_requests_path, notice: "有給申請を提出しました"
    else
      @remaining_days = current_worker.total_paid_leave_remaining
      render :new, status: :unprocessable_entity
    end
  end

  def cancel
    @request = current_worker.paid_leave_requests.find(params[:id])

    if @request.pending?
      @request.cancel!
      redirect_to paid_leave_requests_path, notice: "申請をキャンセルしました"
    else
      redirect_to paid_leave_requests_path, alert: "承認待ち以外の申請はキャンセルできません"
    end
  end

  private

  def request_params
    params.require(:paid_leave_request).permit(:leave_date, :leave_type, :reason)
  end
end
