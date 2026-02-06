# frozen_string_literal: true

# 全案件の単価テンプレート管理用インデックス
class CostTemplatesController < ApplicationController
  authorize_with :projects

  def index
    @projects = Project.includes(:project_cost_templates)
                       .where(status: %w[ordered preparing in_progress])
                       .order(:code)
    @projects_with_templates = @projects.select { |p| p.project_cost_templates.any? }
    @projects_without_templates = @projects.reject { |p| p.project_cost_templates.any? }
  end
end
