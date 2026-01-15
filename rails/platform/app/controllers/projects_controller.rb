# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :authorize_projects_access
  before_action :set_project, only: %i[show edit update destroy complete_four_point]

  def index
    @projects = Project.includes(:client).order(created_at: :desc)
    @projects = @projects.active if params[:active] == "true"
  end

  def show; end

  def new
    @project = Project.new
  end

  def edit; end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to @project, notice: "案件を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "案件を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @project.destroy
      redirect_to projects_url, notice: "案件を削除しました"
    else
      redirect_to @project, alert: "案件の削除に失敗しました: #{@project.errors.full_messages.join(', ')}"
    end
  end

  def complete_four_point
    if @project.complete_four_point_check!
      redirect_to @project, notice: "4点チェックを完了し、受注済みに更新しました"
    else
      redirect_to @project, alert: "4点チェックが完了していません。全ての項目を確認してください"
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def authorize_projects_access
    authorize_feature!(:projects)
  end

  def project_params
    params.require(:project).permit(
      :code, :name, :client_id, :sales_user_id, :engineering_user_id,
      :construction_user_id, :status, :project_type, :estimated_amount, :order_amount,
      :budget_amount, :site_address, :has_contract, :has_order,
      :has_payment_terms, :has_customer_approval, :drive_folder_url
    )
  end
end
