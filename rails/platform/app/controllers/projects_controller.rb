# frozen_string_literal: true

class ProjectsController < ApplicationController
  authorize_with :projects
  before_action :set_project, only: %i[show edit update destroy complete_four_point complete_pre_construction_gate start_construction]

  def index
    @projects = Project.includes(:client).order(created_at: :desc)

    case params[:filter]
    when "active"
      @projects = @projects.active
    when "four_point"
      # 4点チェック未完了（見積中以下のステータス）
      @projects = @projects.where(four_point_completed_at: nil)
                           .where(status: %w[draft estimating])
    end
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

  def complete_pre_construction_gate
    if @project.complete_pre_construction_gate!
      redirect_to @project, notice: "着工前ゲートを完了し、着工準備中に更新しました"
    else
      redirect_to @project, alert: "着工前ゲートが完了していません。全ての項目を確認してください"
    end
  end

  def start_construction
    if @project.start_construction!
      redirect_to @project, notice: "着工を開始しました"
    else
      redirect_to @project, alert: "着工を開始できません。着工準備中ステータスであることを確認してください"
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(
      :code, :name, :client_id, :sales_user_id, :engineering_user_id,
      :construction_user_id, :status, :project_type, :estimated_amount, :order_amount,
      :budget_amount, :site_address, :has_contract, :has_order,
      :has_payment_terms, :has_customer_approval, :drive_folder_url,
      :site_conditions_checked, :night_work_checked, :regulations_checked,
      :safety_docs_checked, :delivery_checked,
      :scheduled_start_date, :scheduled_end_date, :actual_start_date, :actual_end_date,
      :order_flow, :oral_order_amount, :oral_order_received_at, :oral_order_note,
      :order_document_received_at, :description, :estimate_memo
    )
  end
end
