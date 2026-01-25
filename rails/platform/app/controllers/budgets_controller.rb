# frozen_string_literal: true

class BudgetsController < ApplicationController
  authorize_with :budgets
  before_action :set_project
  before_action :set_budget, only: %i[show edit update confirm]

  def show; end

  def new
    @budget = @project.build_budget
  end

  def edit; end

  def create
    @budget = @project.build_budget(budget_params)

    if @budget.save
      redirect_to project_budget_path(@project), notice: "実行予算を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @budget.update(budget_params)
      redirect_to project_budget_path(@project), notice: "実行予算を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    if @budget.status == "draft"
      @budget.confirm!(current_employee)
      redirect_to project_budget_path(@project), notice: "実行予算を確定しました"
    else
      redirect_to project_budget_path(@project), alert: "この予算は既に確定済みです"
    end
  end

  def import_from_estimate
    estimate = @project.estimate

    unless estimate
      redirect_to edit_project_budget_path(@project), alert: "見積書がありません"
      return
    end

    unless estimate.can_import_to_budget?
      redirect_to edit_project_budget_path(@project), alert: "提出済みまたは承認済みの見積書のみ取り込み可能です"
      return
    end

    @budget = @project.budget || @project.build_budget
    @budget.assign_attributes(
      material_cost: estimate.material_cost,
      outsourcing_cost: estimate.outsourcing_cost,
      labor_cost: estimate.labor_cost,
      expense_cost: estimate.expense_cost
    )

    if @budget.save
      redirect_to edit_project_budget_path(@project), notice: "見積書の原価を取り込みました。必要に応じて調整してください。"
    else
      redirect_to edit_project_budget_path(@project), alert: "取り込みに失敗しました"
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_budget
    @budget = @project.budget || @project.build_budget
  end

  def budget_params
    params.require(:budget).permit(
      :target_profit_rate, :material_cost, :outsourcing_cost,
      :labor_cost, :expense_cost, :labor_unit_price, :notes
    )
  end
end
