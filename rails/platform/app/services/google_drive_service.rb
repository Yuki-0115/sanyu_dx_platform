# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "base64"

# Google Drive連携サービス（n8n経由）
# - 案件フォルダの自動作成
# - ドキュメントのアップロード
class GoogleDriveService
  include Singleton

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
    delegate :upload_document, :upload_expense_receipt, :upload_monthly_report,
             :enabled?, to: :instance
  end

  def initialize
    @n8n_webhook_url = ENV.fetch("N8N_DRIVE_WEBHOOK_URL", "http://sanyu-n8n:5678/webhook/drive-upload")
  end

  def enabled?
    ENV.fetch("GOOGLE_DRIVE_ENABLED", "true") == "true"
  end

  # ProjectDocumentをGoogle Driveにアップロード
  def upload_document(document)
    return nil unless enabled?
    return nil unless document.file.attached?

    project = document.project
    folder_name = project ? "#{project.code}_#{project.name}" : "その他"
    subfolder = category_to_subfolder(document.category)
    full_folder_name = "#{folder_name}/#{subfolder}"

    upload_file(
      attachment: document.file,
      folder_name: full_folder_name,
      file_name: "#{document.name}_#{document.file.filename}"
    )
  end

  # 経費の領収書をアップロード
  def upload_expense_receipt(expense)
    return nil unless enabled?
    return nil unless expense.receipt.attached?

    folder_name = if expense.project
                    "#{expense.project.code}_#{expense.project.name}/06_請求・入金/領収書"
                  else
                    "経費/#{expense.expense_date&.strftime('%Y年%m月')}"
                  end

    upload_file(
      attachment: expense.receipt,
      folder_name: folder_name,
      file_name: "#{expense.expense_date}_#{expense.category}_#{expense.receipt.filename}"
    )
  end

  # 月次帳票をアップロード
  def upload_monthly_report(file_path:, file_name:, year:, month:)
    return nil unless enabled?
    return nil unless File.exist?(file_path)

    folder_name = "月次帳票/#{year}年/#{month}月"

    file_data = Base64.strict_encode64(File.read(file_path))

    send_to_n8n(
      folder_name: folder_name,
      file_name: file_name,
      file_data: file_data,
      mime_type: "text/csv"
    )
  end

  private

  def upload_file(attachment:, folder_name:, file_name:)
    attachment.open do |tempfile|
      file_data = Base64.strict_encode64(tempfile.read)

      send_to_n8n(
        folder_name: folder_name,
        file_name: file_name.to_s,
        file_data: file_data,
        mime_type: attachment.content_type
      )
    end
  end

  def send_to_n8n(folder_name:, file_name:, file_data:, mime_type:)
    uri = URI.parse(@n8n_webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = {
      folder_name: folder_name,
      file_name: file_name,
      file_data: file_data,
      mime_type: mime_type,
      timestamp: Time.current.iso8601
    }.to_json

    response = http.request(request)

    if response.code.to_i.between?(200, 299)
      Rails.logger.info "[GoogleDriveService] Upload sent: #{file_name} -> #{folder_name}"
      { success: true, response_code: response.code }
    else
      Rails.logger.warn "[GoogleDriveService] Upload failed: #{response.code} - #{response.body}"
      { success: false, response_code: response.code, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error "[GoogleDriveService] Error: #{e.message}"
    { success: false, error: e.message }
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
end
