# frozen_string_literal: true

# Google Driveへの非同期同期ジョブ
class GoogleDriveSyncJob < ApplicationJob
  queue_as :default

  def perform(action:, record_type:, record_id:, options: {})
    return unless GoogleDriveService.enabled?

    record = record_type.constantize.find_by(id: record_id)
    return unless record

    case action.to_s
    when "create_project_folder"
      GoogleDriveService.create_project_folder(record)
    when "upload_document"
      GoogleDriveService.upload_document(record)
    when "create_monthly_folder"
      year = options[:year] || Time.current.year
      month = options[:month] || Time.current.month
      GoogleDriveService.create_monthly_report_folder(year, month)
    else
      Rails.logger.warn "[GoogleDriveSyncJob] Unknown action: #{action}"
    end
  end
end
