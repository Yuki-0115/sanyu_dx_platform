# frozen_string_literal: true

class ProjectDocument < ApplicationRecord

  # カテゴリ定義
  CATEGORIES = %w[
    contract
    site_management
    safety
    completion
    photo
    other
  ].freeze

  CATEGORY_LABELS = {
    "contract" => "契約関連",
    "site_management" => "現場管理",
    "safety" => "安全書類",
    "completion" => "完工・請求",
    "photo" => "写真・資料",
    "other" => "その他"
  }.freeze

  CATEGORY_ICONS = {
    "contract" => "document-text",
    "site_management" => "clipboard-document-list",
    "safety" => "shield-check",
    "completion" => "check-badge",
    "photo" => "photo",
    "other" => "folder"
  }.freeze

  # Associations
  belongs_to :project
  belongs_to :uploaded_by, class_name: "Employee", optional: true

  # Active Storage
  has_one_attached :file

  # Validations
  validates :name, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  # Callbacks
  after_create_commit :sync_to_google_drive

  # Scopes
  scope :by_category, ->(cat) { where(category: cat) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def category_label
    CATEGORY_LABELS[category] || category
  end

  def category_icon
    CATEGORY_ICONS[category] || "document"
  end

  def file_extension
    return nil unless file.attached?

    File.extname(file.filename.to_s).delete(".").upcase
  end

  def file_size_display
    return nil unless file.attached?

    size = file.byte_size
    if size < 1024
      "#{size} B"
    elsif size < 1024 * 1024
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / (1024.0 * 1024)).round(1)} MB"
    end
  end

  private

  def sync_to_google_drive
    return unless file.attached?

    GoogleDriveSyncJob.perform_later(
      action: "upload_document",
      record_type: "ProjectDocument",
      record_id: id
    )
  end
end
