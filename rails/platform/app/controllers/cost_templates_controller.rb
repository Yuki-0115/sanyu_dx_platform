# frozen_string_literal: true

# 日報用原価テンプレート管理用インデックス
class CostTemplatesController < ApplicationController
  authorize_with :projects

  def index
    @base_templates = BaseCostTemplate.ordered
    @base_templates_by_category = @base_templates.group_by(&:category)

    @projects = Project.includes(:project_cost_templates)
                       .where(status: %w[ordered preparing in_progress])
                       .order(:code)
    @projects_with_templates = @projects.select { |p| p.project_cost_templates.any? }
    @projects_without_templates = @projects.reject { |p| p.project_cost_templates.any? }
  end
end
