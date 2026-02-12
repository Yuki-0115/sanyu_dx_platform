# frozen_string_literal: true

# 基本単価（全案件共通）の管理
class BaseCostTemplatesController < ApplicationController
  authorize_with :projects

  before_action :set_template, only: %i[edit update destroy]

  def index
    @templates = BaseCostTemplate.ordered
    @templates_by_category = @templates.group_by(&:category)
  end

  def new
    @template = BaseCostTemplate.new
  end

  def create
    @template = BaseCostTemplate.new(template_params)

    if @template.save
      redirect_to base_cost_templates_path, notice: "基本単価を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to base_cost_templates_path, notice: "基本単価を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to base_cost_templates_path, notice: "基本単価を削除しました"
  end

  private

  def set_template
    @template = BaseCostTemplate.find(params[:id])
  end

  def template_params
    params.require(:base_cost_template).permit(
      :category, :item_name, :unit, :unit_price, :note, :sort_order
    )
  end
end
