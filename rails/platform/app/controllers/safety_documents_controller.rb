# frozen_string_literal: true

class SafetyDocumentsController < ApplicationController
  authorize_with :safety_documents
  before_action :set_folder, only: %i[show edit_folder update_folder destroy_folder]
  before_action :set_file, only: %i[edit_file update_file destroy_file]

  # フォルダ一覧
  def index
    @folders = SafetyFolder.includes(:project).order(:name)
    @folders = @folders.for_project(params[:project_id]) if params[:project_id].present?
  end

  # フォルダ詳細（ファイル一覧）
  def show
    @files = @folder.safety_files.includes(:uploaded_by).order(created_at: :desc)
  end

  # フォルダ新規作成フォーム
  def new_folder
    @folder = SafetyFolder.new
    @folder.project_id = params[:project_id] if params[:project_id].present?
  end

  # フォルダ作成
  def create_folder
    @folder = SafetyFolder.new(folder_params)

    if @folder.save
      redirect_to safety_document_path(@folder), notice: "フォルダを作成しました"
    else
      render :new_folder, status: :unprocessable_entity
    end
  end

  # フォルダ編集フォーム
  def edit_folder; end

  # フォルダ更新
  def update_folder
    if @folder.update(folder_params)
      redirect_to safety_document_path(@folder), notice: "フォルダを更新しました"
    else
      render :edit_folder, status: :unprocessable_entity
    end
  end

  # フォルダ削除
  def destroy_folder
    @folder.destroy
    redirect_to safety_documents_path, notice: "フォルダを削除しました"
  end

  # ファイルアップロードフォーム
  def new_file
    @folder = SafetyFolder.find(params[:folder_id])
    @file = @folder.safety_files.build
  end

  # ファイルアップロード
  def create_file
    @folder = SafetyFolder.find(params[:folder_id])
    @file = @folder.safety_files.build(file_params)
    @file.uploaded_by = current_employee

    if @file.save
      redirect_to safety_document_path(@folder), notice: "ファイルをアップロードしました"
    else
      render :new_file, status: :unprocessable_entity
    end
  end

  # ファイル編集フォーム
  def edit_file
    @folder = @file.safety_folder
  end

  # ファイル更新
  def update_file
    @folder = @file.safety_folder

    if @file.update(file_params)
      redirect_to safety_document_path(@folder), notice: "ファイル情報を更新しました"
    else
      render :edit_file, status: :unprocessable_entity
    end
  end

  # ファイル削除
  def destroy_file
    folder = @file.safety_folder
    @file.destroy
    redirect_to safety_document_path(folder), notice: "ファイルを削除しました"
  end

  private

  def set_folder
    @folder = SafetyFolder.find(params[:id])
  end

  def set_file
    @file = SafetyFile.find(params[:id])
  end

  def folder_params
    params.require(:safety_folder).permit(:name, :description, :project_id)
  end

  def file_params
    params.require(:safety_file).permit(:name, :description, attachments: [])
  end
end
