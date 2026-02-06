# frozen_string_literal: true

class SafetyFolder < ApplicationRecord
  # 後方互換性のための定数（SafetyDocumentTypeから取得）
  def self.required_documents
    SafetyDocumentType.required_documents_with_fallback
  end

  # ビュー用の別名（REQUIRED_DOCUMENTSとして使われていた箇所に対応）
  REQUIRED_DOCUMENTS = SafetyDocumentType::DEFAULT_DOCUMENTS

  # Associations
  belongs_to :project, optional: true
  has_many :safety_files, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Scopes
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :general, -> { where(project_id: nil) }
  scope :with_files, -> { where("files_count > 0") }

  # Counter cache
  def update_files_count!
    update_column(:files_count, safety_files.count)
  end

  # 案件の安全書類提出状況を取得
  def self.submission_status_for(project)
    existing_folders = where(project_id: project.id).pluck(:name)
    docs = required_documents

    docs.map do |doc|
      folder = find_by(project_id: project.id, name: doc[:name])
      {
        name: doc[:name],
        description: doc[:description],
        submitted: existing_folders.include?(doc[:name]),
        folder: folder,
        files_count: folder&.files_count || 0
      }
    end
  end

  # 案件の提出率を計算
  def self.submission_rate_for(project)
    status = submission_status_for(project)
    submitted_count = status.count { |s| s[:submitted] && s[:files_count] > 0 }
    total = status.size
    total > 0 ? (submitted_count.to_f / total * 100).round : 0
  end
end
