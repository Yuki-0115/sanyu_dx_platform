# frozen_string_literal: true

class ProjectCostTemplatesController < ApplicationController
  include ProjectScoped

  # 営業・工務のみ編集可能、職長は日報画面から閲覧のみ
  authorize_with :projects

  before_action :set_template, only: %i[edit update destroy]

  def index
    @templates = @project.project_cost_templates.ordered
    @templates_by_category = @templates.group_by(&:category)
  end

  def new
    @template = @project.project_cost_templates.build
  end

  def create
    @template = @project.project_cost_templates.build(template_params)

    if @template.save
      redirect_to project_project_cost_templates_path(@project), notice: "現場単価を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      redirect_to project_project_cost_templates_path(@project), notice: "現場単価を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @template.destroy
    redirect_to project_project_cost_templates_path(@project), notice: "現場単価を削除しました"
  end

  private

  def set_template
    @template = @project.project_cost_templates.find(params[:id])
  end

  def template_params
    params.require(:project_cost_template).permit(
      :category, :item_name, :unit, :unit_price, :note, :sort_order
    )
  end
end
