# frozen_string_literal: true

require "google/apis/drive_v3"

# Google Drive API連携サービス
# - 案件フォルダの自動作成
# - ドキュメントのアップロード・同期
# - 月次帳票の自動保存
class GoogleDriveService
  include Singleton

  SCOPES = [Google::Apis::DriveV3::AUTH_DRIVE_FILE].freeze

  # フォルダ構成テンプレート
  PROJECT_FOLDERS = %w[
    01_見積・契約
    02_現場管理
    03_安全書類
    04_写真
    05_竣工書類
    06_請求・入金
  ].freeze

  class << self
    delegate :create_project_folder, :upload_file, :upload_document,
             :create_monthly_report_folder, :get_folder_url,
             :enabled?, to: :instance
  end

  def initialize
    @credentials_path = ENV.fetch("GOOGLE_DRIVE_CREDENTIALS_PATH", nil)
    @root_folder_id = ENV.fetch("GOOGLE_DRIVE_ROOT_FOLDER_ID", nil)
    @drive_service = nil
  end

  def enabled?
    @credentials_path.present? && @root_folder_id.present? && File.exist?(@credentials_path.to_s)
  end

  # 案件フォルダを作成し、サブフォルダも自動生成
  def create_project_folder(project)
    return nil unless enabled?

    # メインフォルダ作成
    folder_name = "#{project.code}_#{project.name}"
    main_folder = create_folder(folder_name, @root_folder_id)
    return nil unless main_folder

    # サブフォルダ作成
    PROJECT_FOLDERS.each do |subfolder_name|
      create_folder(subfolder_name, main_folder.id)
    end

    # 案件にフォルダURLを保存
    folder_url = "https://drive.google.com/drive/folders/#{main_folder.id}"
    project.update_column(:drive_folder_url, folder_url)

    Rails.logger.info "[GoogleDriveService] Created project folder: #{folder_name}"
    { folder_id: main_folder.id, folder_url: folder_url }
  rescue Google::Apis::Error => e
    Rails.logger.error "[GoogleDriveService] Error creating project folder: #{e.message}"
    nil
  end

  # ファイルをアップロード
  def upload_file(file_path:, file_name:, folder_id:, mime_type: nil)
    return nil unless enabled?

    mime_type ||= detect_mime_type(file_name)

    file_metadata = Google::Apis::DriveV3::File.new(
      name: file_name,
      parents: [folder_id]
    )

    result = drive_service.create_file(
      file_metadata,
      upload_source: file_path,
      content_type: mime_type,
      fields: "id, name, webViewLink"
    )

    Rails.logger.info "[GoogleDriveService] Uploaded file: #{file_name}"
    { file_id: result.id, file_name: result.name, web_link: result.web_view_link }
  rescue Google::Apis::Error => e
    Rails.logger.error "[GoogleDriveService] Error uploading file: #{e.message}"
    nil
  end

  # Active Storageの添付ファイルをアップロード
  def upload_attachment(attachment:, folder_id:, file_name: nil)
    return nil unless enabled?
    return nil unless attachment.attached?

    file_name ||= attachment.filename.to_s
    mime_type = attachment.content_type

    # 一時ファイルに保存してアップロード
    attachment.open do |tempfile|
      upload_file(
        file_path: tempfile.path,
        file_name: file_name,
        folder_id: folder_id,
        mime_type: mime_type
      )
    end
  end

  # ProjectDocumentをGoogle Driveにアップロード
  def upload_document(document)
    return nil unless enabled?
    return nil unless document.file.attached?

    project = document.project
    return nil unless project&.drive_folder_url

    # フォルダIDを取得
    folder_id = extract_folder_id(project.drive_folder_url)
    return nil unless folder_id

    # カテゴリに応じたサブフォルダを特定
    subfolder_name = category_to_subfolder(document.category)
    subfolder = find_or_create_subfolder(folder_id, subfolder_name)
    target_folder_id = subfolder&.id || folder_id

    # ファイルをアップロード
    result = upload_attachment(
      attachment: document.file,
      folder_id: target_folder_id,
      file_name: "#{document.name}_#{document.file.filename}"
    )

    # ドキュメントにDriveリンクを保存
    if result
      document.update_column(:drive_file_url, result[:web_link])
    end

    result
  end

  # 月次帳票フォルダを作成
  def create_monthly_report_folder(year, month)
    return nil unless enabled?

    # 月次帳票用のルートフォルダを探すか作成
    reports_root = find_or_create_subfolder(@root_folder_id, "月次帳票")
    return nil unless reports_root

    # 年フォルダ
    year_folder = find_or_create_subfolder(reports_root.id, "#{year}年")
    return nil unless year_folder

    # 月フォルダ
    month_folder = find_or_create_subfolder(year_folder.id, "#{month}月")
    return nil unless month_folder

    folder_url = "https://drive.google.com/drive/folders/#{month_folder.id}"
    { folder_id: month_folder.id, folder_url: folder_url }
  end

  # フォルダURLを取得
  def get_folder_url(folder_id)
    "https://drive.google.com/drive/folders/#{folder_id}"
  end

  private

  def drive_service
    @drive_service ||= begin
      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = authorize
      service
    end
  end

  def authorize
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(@credentials_path),
      scope: SCOPES
    )
  end

  def create_folder(name, parent_id)
    file_metadata = Google::Apis::DriveV3::File.new(
      name: name,
      mime_type: "application/vnd.google-apps.folder",
      parents: [parent_id]
    )

    drive_service.create_file(file_metadata, fields: "id, name, webViewLink")
  end

  def find_or_create_subfolder(parent_id, folder_name)
    # 既存フォルダを検索
    query = "name = '#{folder_name}' and '#{parent_id}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
    result = drive_service.list_files(q: query, fields: "files(id, name)")

    if result.files.any?
      result.files.first
    else
      create_folder(folder_name, parent_id)
    end
  end

  def extract_folder_id(drive_url)
    return nil unless drive_url

    # URLからフォルダIDを抽出
    match = drive_url.match(%r{/folders/([a-zA-Z0-9_-]+)})
    match&.captures&.first
  end

  def category_to_subfolder(category)
    case category
    when "contract"
      "01_見積・契約"
    when "site_management"
      "02_現場管理"
    when "safety"
      "03_安全書類"
    when "photo"
      "04_写真"
    when "completion"
      "05_竣工書類"
    else
      "02_現場管理"
    end
  end

  def detect_mime_type(file_name)
    extension = File.extname(file_name).downcase
    case extension
    when ".pdf"
      "application/pdf"
    when ".jpg", ".jpeg"
      "image/jpeg"
    when ".png"
      "image/png"
    when ".xlsx"
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    when ".xls"
      "application/vnd.ms-excel"
    when ".docx"
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    when ".doc"
      "application/msword"
    else
      "application/octet-stream"
    end
  end
end
