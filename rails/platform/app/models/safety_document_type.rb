# frozen_string_literal: true

class SafetyDocumentType < ApplicationRecord
  # デフォルトの安全書類種類
  DEFAULT_DOCUMENTS = [
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
  has_many :project_safety_requirements, dependent: :destroy
  has_many :projects, through: :project_safety_requirements

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :position, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position) }

  # デフォルトの書類種類を初期登録
  def self.seed_defaults
    DEFAULT_DOCUMENTS.each_with_index do |doc, index|
      find_or_create_by!(name: doc[:name]) do |record|
        record.description = doc[:description]
        record.position = index + 1
        record.active = true
      end
    end
  end

  # SafetyFolderで使用する形式で返す
  def self.required_documents
    active.ordered.map do |doc|
      { name: doc.name, description: doc.description }
    end
  end

  # データがなければデフォルトを返す
  def self.required_documents_with_fallback
    if active.any?
      required_documents
    else
      DEFAULT_DOCUMENTS
    end
  end
end
