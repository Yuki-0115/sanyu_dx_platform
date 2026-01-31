# frozen_string_literal: true

# コントローラー間で共通のプロジェクト取得ロジック
module ProjectScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_project
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
