# frozen_string_literal: true

class ProjectDocument < ApplicationRecord

  # ファイルサイズ・タイプ制限
  MAX_FILE_SIZE = 100.megabytes
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    image/png
    image/jpeg
    image/webp
    image/gif
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-powerpoint
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    text/plain
    text/csv
  ].freeze

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
  validate :validate_file_attachment

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

  def validate_file_attachment
    return unless file.attached?

    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "は#{MAX_FILE_SIZE / 1.megabyte}MB以下にしてください")
    end

    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      errors.add(:file, "は許可されていないファイル形式です")
    end
  end
end
