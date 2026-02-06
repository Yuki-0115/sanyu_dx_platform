# frozen_string_literal: true

class SafetyFolder < ApplicationRecord
  # 必須安全書類の種類
  REQUIRED_DOCUMENTS = [
    { name: "作業員名簿", description: "現場作業員の名簿" },
    { name: "新規入場者教育記録", description: "新規入場時の安全教育記録" },
    { name: "安全衛生管理計画書", description: "現場の安全衛生計画" },
    { name: "工事安全衛生計画書", description: "工事全体の安全計画" },
    { name: "施工体制台帳", description: "下請業者を含む施工体制" },
    { name: "再下請負通知書", description: "再下請負の通知書類" },
    { name: "持込機械届", description: "持込機械の届出書類" },
    { name: "火気使用届", description: "溶接等火気使用の届出" },
    { name: "有資格者一覧", description: "資格保有者の一覧" },
    { name: "健康診断結果報告書", description: "作業員の健康診断結果" }
  ].freeze

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

    REQUIRED_DOCUMENTS.map do |doc|
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
