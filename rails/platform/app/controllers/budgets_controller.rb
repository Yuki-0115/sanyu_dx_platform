# frozen_string_literal: true

class BudgetsController < ApplicationController
  before_action :authorize_budgets_access
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

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_budget
    @budget = @project.budget || @project.build_budget
  end

  def authorize_budgets_access
    authorize_feature!(:budgets)
  end

  def budget_params
    params.require(:budget).permit(
      :target_profit_rate, :material_cost, :outsourcing_cost,
      :labor_cost, :expense_cost, :notes
    )
  end
end
