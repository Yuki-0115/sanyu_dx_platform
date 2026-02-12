# frozen_string_literal: true

class SafetyDocTrackingController < ApplicationController
  authorize_with :safety_documents

  def index
    @projects = Project.where(status: %w[ordered preparing in_progress completed invoiced])
                       .includes(:client, :chief_engineer, :site_agent, :safety_doc_person)
                       .order(created_at: :desc)
  end

  def update
    @project = Project.find(params[:id])
    if @project.update(safety_doc_params)
      redirect_to safety_doc_tracking_index_path, notice: "更新しました"
    else
      redirect_to safety_doc_tracking_index_path, alert: "更新に失敗しました"
    end
  end

  private

  def safety_doc_params
    params.require(:project).permit(:safety_doc_status, :safety_doc_method)
  end
end
