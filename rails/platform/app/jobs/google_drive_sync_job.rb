# frozen_string_literal: true

# Google Driveへの非同期同期ジョブ
# rclone版を優先し、利用できない場合はn8n版にフォールバック
class GoogleDriveSyncJob < ApplicationJob
  queue_as :default

  def perform(action:, record_type:, record_id:, options: {})
    record = record_type.constantize.find_by(id: record_id)
    return unless record

    # rclone版を優先
    if GoogleDriveRcloneService.enabled?
      perform_with_rclone(action, record, options)
    elsif GoogleDriveService.enabled?
      perform_with_n8n(action, record, options)
    else
      Rails.logger.info "[GoogleDriveSyncJob] Google Drive sync is disabled"
    end
  end

  private

  def perform_with_rclone(action, record, options)
    case action.to_s
    when "create_project_folder"
      GoogleDriveRcloneService.create_project_folder(record)
    when "upload_document"
      GoogleDriveRcloneService.upload_document(record)
    when "upload_receipt"
      GoogleDriveRcloneService.upload_expense_receipt(record)
    when "upload_photo"
      # 日報写真の場合
      if record.is_a?(DailyReport) && options[:photo_index]
        photo = record.photos[options[:photo_index].to_i]
        GoogleDriveRcloneService.upload_daily_report_photo(record, photo) if photo
      end
    else
      Rails.logger.warn "[GoogleDriveSyncJob] Unknown action for rclone: #{action}"
    end
  end

  def perform_with_n8n(action, record, options)
    case action.to_s
    when "upload_document"
      GoogleDriveService.upload_document(record)
    when "upload_receipt"
      GoogleDriveService.upload_expense_receipt(record)
    when "upload_monthly_report"
      GoogleDriveService.upload_monthly_report(
        file_path: options[:file_path],
        file_name: options[:file_name],
        year: options[:year],
        month: options[:month]
      )
    else
      Rails.logger.warn "[GoogleDriveSyncJob] Unknown action for n8n: #{action}"
    end
  end
end
