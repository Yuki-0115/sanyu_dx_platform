# frozen_string_literal: true

# Google Driveへの非同期同期ジョブ（n8n経由）
class GoogleDriveSyncJob < ApplicationJob
  queue_as :default

  def perform(action:, record_type:, record_id:, options: {})
    return unless GoogleDriveService.enabled?

    record = record_type.constantize.find_by(id: record_id)
    return unless record

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
      Rails.logger.warn "[GoogleDriveSyncJob] Unknown action: #{action}"
    end
  end
end
