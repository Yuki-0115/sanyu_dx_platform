# frozen_string_literal: true

class SafetyFile < ApplicationRecord

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
  ].freeze

  # Associations
  belongs_to :safety_folder, counter_cache: :files_count, optional: true
  belongs_to :project, optional: true
  belongs_to :safety_document_type, optional: true
  belongs_to :uploaded_by, class_name: "Employee", optional: true

  # ファイル添付（複数可）
  has_many_attached :attachments

  # Validations
  validates :name, presence: true
  validate :validate_attachments
  validate :validate_project_or_folder

  # Scopes
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :for_category, ->(type_id) { where(safety_document_type_id: type_id) }
  scope :ordered, -> { order(created_at: :desc) }

  # Callbacks
  after_save :update_folder_count
  after_destroy :update_folder_count

  # カテゴリ名を取得
  def category_name
    safety_document_type&.name || "未分類"
  end

  private

  def update_folder_count
    safety_folder&.update_files_count!
  end

  def validate_project_or_folder
    if project_id.blank? && safety_folder_id.blank?
      errors.add(:base, "案件またはフォルダを指定してください")
    end
  end

  def validate_attachments
    return unless attachments.attached?

    attachments.each do |attachment|
      if attachment.byte_size > MAX_FILE_SIZE
        errors.add(:attachments, "は1ファイル#{MAX_FILE_SIZE / 1.megabyte}MB以下にしてください")
      end

      unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, "は許可されていないファイル形式です（PDF、画像、Word、Excelのみ）")
      end
    end
  end
end
