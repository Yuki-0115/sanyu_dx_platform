# frozen_string_literal: true

class EstimatesController < ApplicationController
  authorize_with :estimates
  before_action :set_project
  before_action :set_estimate, only: %i[show edit update approve]

  def show; end

  def new
    @estimate = @project.build_estimate(
      created_by: current_employee,
      estimate_date: Date.current,
      valid_until: Date.current + 30.days
    )
  end

  def create
    @estimate = @project.build_estimate(estimate_params)
    @estimate.created_by = current_employee

    if @estimate.save
      redirect_to project_estimate_path(@project), notice: "見積書を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @estimate.update(estimate_params)
      redirect_to project_estimate_path(@project), notice: "見積書を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    if @estimate.status == "submitted"
      @estimate.update!(status: "approved")
      redirect_to project_estimate_path(@project), notice: "見積書を承認しました"
    else
      redirect_to project_estimate_path(@project), alert: "提出済みの見積書のみ承認できます"
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_estimate
    @estimate = @project.estimate
    redirect_to new_project_estimate_path(@project), alert: "見積書がありません" unless @estimate
  end

  def estimate_params
    params.require(:estimate).permit(
      :estimate_number, :estimate_date, :valid_until, :status,
      :material_cost, :outsourcing_cost, :labor_cost, :expense_cost,
      :selling_price, :notes
    )
  end
end
