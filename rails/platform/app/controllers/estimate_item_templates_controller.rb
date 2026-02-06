# frozen_string_literal: true

class EstimateItemTemplatesController < ApplicationController
  authorize_with :master

  before_action :set_template, only: %i[edit update destroy]

  def index
    @templates = EstimateItemTemplate.available_for(current_employee).ordered
    @grouped_templates = @templates.group_by(&:category)
  end

  def new
    @template = EstimateItemTemplate.new
  end

  def create
    @template = EstimateItemTemplate.new(template_params)
    @template.employee = current_employee unless @template.is_shared

    if @template.save
      redirect_to estimate_item_templates_path, notice: "項目テンプレートを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to estimate_item_templates_path, notice: "項目テンプレートを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to estimate_item_templates_path, notice: "項目テンプレートを削除しました"
  end

  private

  def set_template
    @template = EstimateItemTemplate.find(params[:id])
    unless @template.is_shared || @template.employee_id == current_employee.id
      redirect_to estimate_item_templates_path, alert: "編集権限がありません"
    end
  end

  def template_params
    params.require(:estimate_item_template).permit(
      :name, :category, :unit, :default_unit_price, :specification, :note, :sort_order, :is_shared
    )
  end

  def can_manage_shared?
    current_employee.admin? || current_employee.management?
  end
  helper_method :can_manage_shared?
end
