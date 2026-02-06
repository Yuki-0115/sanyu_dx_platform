# frozen_string_literal: true

class SafetyDocumentsController < ApplicationController
  authorize_with :safety_documents
  before_action :set_project, only: %i[project_files new_project_file create_project_file]
  before_action :set_file, only: %i[edit_file update_file destroy_file]

  # 案件一覧（提出状況）
  def index
    @projects = Project.where(status: %w[in_progress preparing ordered estimating])
                       .includes(:client, :sales_user, :safety_files)
                       .order(scheduled_start_date: :desc)

    # 各案件の提出状況を計算
    @project_statuses = @projects.map do |project|
      status = submission_status_for(project)
      submitted_count = status.count { |s| s[:submitted] }
      {
        project: project,
        status: status,
        submitted_count: submitted_count,
        total_count: status.size,
        rate: status.size > 0 ? (submitted_count.to_f / status.size * 100).round : 0
      }
    end

    # フィルター
    if params[:filter] == "incomplete"
      @project_statuses = @project_statuses.select { |ps| ps[:rate] < 100 }
    elsif params[:filter] == "complete"
      @project_statuses = @project_statuses.select { |ps| ps[:rate] == 100 }
    end
  end

  # 案件の書類一覧
  def project_files
    @document_types = SafetyFolder.required_documents_for(@project)
    @files_by_type = @project.safety_files.includes(:safety_document_type, :uploaded_by)
                             .group_by(&:safety_document_type_id)
    @uncategorized_files = @project.safety_files.where(safety_document_type_id: nil)
  end

  # 新規ファイルアップロードフォーム
  def new_project_file
    @file = SafetyFile.new(project: @project)
    @document_types = SafetyDocumentType.active.ordered
    # パラメータでカテゴリが指定されている場合
    @file.safety_document_type_id = params[:category_id] if params[:category_id].present?
  end

  # ファイルアップロード
  def create_project_file
    @file = SafetyFile.new(project_file_params)
    @file.project = @project
    @file.uploaded_by = current_employee

    if @file.save
      redirect_to project_files_safety_documents_path(project_id: @project.id),
                  notice: "ファイルをアップロードしました"
    else
      @document_types = SafetyDocumentType.active.ordered
      render :new_project_file, status: :unprocessable_entity
    end
  end

  # ファイル編集フォーム
  def edit_file
    @project = @file.project
    @document_types = SafetyDocumentType.active.ordered
  end

  # ファイル更新
  def update_file
    @project = @file.project

    if @file.update(project_file_params)
      redirect_to project_files_safety_documents_path(project_id: @project.id),
                  notice: "ファイル情報を更新しました"
    else
      @document_types = SafetyDocumentType.active.ordered
      render :edit_file, status: :unprocessable_entity
    end
  end

  # ファイル削除
  def destroy_file
    project = @file.project
    @file.destroy
    redirect_to project_files_safety_documents_path(project_id: project.id),
                notice: "ファイルを削除しました"
  end

  # 案件別必要書類設定フォーム
  def project_requirements
    @project = Project.find(params[:project_id])
    @document_types = SafetyDocumentType.active.ordered
    @selected_ids = @project.required_safety_document_types.pluck(:id)
  end

  # 案件別必要書類設定を保存
  def update_project_requirements
    @project = Project.find(params[:project_id])

    # 既存の設定をクリア
    @project.project_safety_requirements.destroy_all

    # 新しい設定を保存
    if params[:safety_document_type_ids].present?
      params[:safety_document_type_ids].each do |type_id|
        @project.project_safety_requirements.create(safety_document_type_id: type_id)
      end
    end

    redirect_to safety_documents_path, notice: "#{@project.name}の必要書類を設定しました"
  end

  # 全ての書類を必要に設定
  def set_all_requirements
    @project = Project.find(params[:project_id])

    # 既存の設定をクリア
    @project.project_safety_requirements.destroy_all

    # 全ての有効な書類種類を設定
    SafetyDocumentType.active.ordered.each do |doc_type|
      @project.project_safety_requirements.create(safety_document_type: doc_type)
    end

    redirect_to safety_documents_path, notice: "#{@project.name}の必要書類を全て設定しました"
  end

  # 書類設定をクリア（グローバル設定を使用）
  def clear_requirements
    @project = Project.find(params[:project_id])
    @project.project_safety_requirements.destroy_all

    redirect_to safety_documents_path, notice: "#{@project.name}の必要書類設定をクリアしました（共通設定を使用）"
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_file
    @file = SafetyFile.find(params[:id])
  end

  def project_file_params
    params.require(:safety_file).permit(:name, :description, :safety_document_type_id, attachments: [])
  end

  # 案件の提出状況を計算
  def submission_status_for(project)
    required_docs = SafetyFolder.required_documents_for(project)
    files_by_type = project.safety_files.where.not(safety_document_type_id: nil)
                           .group(:safety_document_type_id).count

    required_docs.map do |doc|
      doc_type = SafetyDocumentType.find_by(name: doc[:name])
      files_count = doc_type ? (files_by_type[doc_type.id] || 0) : 0
      {
        name: doc[:name],
        description: doc[:description],
        submitted: files_count > 0,
        files_count: files_count,
        document_type_id: doc_type&.id
      }
    end
  end
end
