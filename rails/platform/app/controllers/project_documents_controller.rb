# frozen_string_literal: true

class ProjectDocumentsController < ApplicationController
  include ProjectScoped

  before_action :set_document, only: %i[destroy]

  def index
    @documents_by_category = @project.project_documents
                                      .includes(:uploaded_by, file_attachment: :blob)
                                      .group_by(&:category)
  end

  def new
    @document = @project.project_documents.build(category: params[:category] || "other")
  end

  def create
    @document = @project.project_documents.build(document_params)
    @document.uploaded_by = current_employee

    if @document.save
      redirect_to project_project_documents_path(@project),
                  notice: "書類「#{@document.name}」をアップロードしました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    name = @document.name
    @document.destroy
    redirect_to project_project_documents_path(@project),
                notice: "書類「#{name}」を削除しました"
  end

  private

  def set_document
    @document = @project.project_documents.find(params[:id])
  end

  def document_params
    params.require(:project_document).permit(:name, :category, :description, :document_date, :file)
  end
end
