# frozen_string_literal: true

# 非同期で通知を送信するJob
# n8n webhook呼び出しまたはLINE WORKS直接通知を行う
class NotificationJob < ApplicationJob
  queue_as :default

  def perform(event_type:, record_type:, record_id:, changes: {})
    record = record_type.constantize.find_by(id: record_id)
    return unless record

    # n8n webhookが設定されている場合はwebhookを呼び出す
    if n8n_webhook_url.present?
      send_n8n_webhook(event_type, record, changes)
    end

    # LINE WORKS直接通知が設定されている場合
    if line_works_enabled?
      send_line_works_notification(event_type, record)
    end
  end

  private

  def send_n8n_webhook(event_type, record, changes)
    payload = {
      event_type: event_type,
      record_type: record.class.name,
      record_id: record.id,
      data: record_data(record),
      changes: changes,
      timestamp: Time.current.iso8601
    }

    uri = URI.parse(n8n_webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)
    Rails.logger.info("n8n webhook sent: #{event_type} -> #{response.code}")
  rescue StandardError => e
    Rails.logger.error("n8n webhook failed: #{e.message}")
  end

  def send_line_works_notification(event_type, record)
    notifier = LineWorksNotifier.new

    case event_type
    when "project_created"
      notifier.notify_project_created(record)
    when "daily_report_created"
      notifier.notify_daily_report_submitted(record)
    when "offset_confirmed"
      notifier.notify_offset_confirmed(record)
    end
  end

  def record_data(record)
    case record
    when Project
      {
        code: record.code,
        name: record.name,
        status: record.status,
        client_name: record.client&.name
      }
    when DailyReport
      {
        project_name: record.project&.name,
        report_date: record.report_date,
        status: record.status
      }
    when Offset
      {
        partner_name: record.partner&.name,
        year_month: record.year_month,
        status: record.status
      }
    else
      { id: record.id }
    end
  end

  def n8n_webhook_url
    ENV.fetch("N8N_WEBHOOK_URL", nil)
  end

  def line_works_enabled?
    ENV.fetch("LINE_WORKS_BOT_ID", nil).present?
  end
end
