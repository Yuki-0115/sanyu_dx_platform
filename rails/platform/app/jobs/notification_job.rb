# frozen_string_literal: true

# 非同期で通知を送信するJob
# LineWorksNotifier経由でn8n webhookまたはLINE WORKS直接通知を行う
class NotificationJob < ApplicationJob
  queue_as :default

  def perform(event_type:, record_type:, record_id:, changes: {})
    record = record_type.constantize.find_by(id: record_id)
    return unless record

    send_notification(event_type, record, changes)
  end

  private

  def send_notification(event_type, record, changes)
    case event_type.to_s
    # 案件関連
    when "project_created"
      LineWorksNotifier.project_created(record)
    when "four_point_completed"
      LineWorksNotifier.four_point_completed(record)
    when "pre_construction_completed"
      LineWorksNotifier.pre_construction_completed(record)
    when "construction_started"
      LineWorksNotifier.construction_started(record)
    when "project_completed"
      LineWorksNotifier.project_completed(record)

    # 予算関連
    when "budget_confirmed"
      LineWorksNotifier.budget_confirmed(record)

    # 日報関連
    when "daily_report_submitted", "daily_report_created"
      LineWorksNotifier.daily_report_submitted(record)
    when "daily_report_confirmed"
      LineWorksNotifier.daily_report_confirmed(record)

    # 請求関連
    when "invoice_issued"
      LineWorksNotifier.invoice_issued(record)
    when "payment_received"
      LineWorksNotifier.payment_received(record)

    # 相殺関連
    when "offset_confirmed"
      LineWorksNotifier.offset_confirmed(record)

    else
      Rails.logger.info "[NotificationJob] Unknown event: #{event_type}"
    end
  end
end
