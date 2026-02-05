# frozen_string_literal: true

class EstimateTemplatesController < ApplicationController
  before_action :authenticate_employee!
  before_action :set_template, only: [:edit, :update, :destroy]
  before_action :authorize_edit!, only: [:edit, :update, :destroy]

  def index
    @condition_templates = EstimateTemplate.condition_templates_for(current_employee)
    @confirmation_templates = EstimateTemplate.confirmation_templates_for(current_employee)
  end

  def new
    @template = EstimateTemplate.new(template_type: params[:type] || "condition")
  end

  def create
    @template = EstimateTemplate.new(template_params)
    @template.employee = current_employee unless @template.is_shared

    # 共有テンプレートは管理者のみ
    if @template.is_shared && !can_manage_shared?
      @template.is_shared = false
    end

    if @template.save
      redirect_to estimate_templates_path, notice: "テンプレートを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    # 共有テンプレートは管理者のみ変更可能
    if template_params[:is_shared] == "1" && !can_manage_shared?
      @template.errors.add(:base, "共有テンプレートの作成は管理者のみ可能です")
      render :edit, status: :unprocessable_entity
      return
    end

    if @template.update(template_params)
      redirect_to estimate_templates_path, notice: "テンプレートを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to estimate_templates_path, notice: "テンプレートを削除しました"
  end

  # AJAX: 見積書フォームからテンプレート作成
  def quick_create
    @template = EstimateTemplate.new(quick_create_params)
    @template.employee = current_employee unless @template.is_shared

    if @template.is_shared && !can_manage_shared?
      @template.is_shared = false
    end

    if @template.save
      render json: { success: true, template: { id: @template.id, name: @template.name } }
    else
      render json: { success: false, errors: @template.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def quick_create_params
    params.permit(:template_type, :name, :content, :is_shared)
  end

  def set_template
    @template = EstimateTemplate.find(params[:id])
  end

  def authorize_edit!
    return if @template.editable_by?(current_employee)

    redirect_to estimate_templates_path, alert: "このテンプレートを編集する権限がありません"
  end

  def can_manage_shared?
    current_employee.role.in?(%w[admin management])
  end
  helper_method :can_manage_shared?

  def template_params
    params.require(:estimate_template).permit(:template_type, :name, :content, :is_shared, :sort_order)
  end
end
