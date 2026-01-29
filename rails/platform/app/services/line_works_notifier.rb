# frozen_string_literal: true

# LINE WORKS通知サービス
# n8n Webhook経由、または直接LINE WORKS APIで通知を送信
class LineWorksNotifier
  include Singleton

  NOTIFICATION_TYPES = {
    project_created: "📋 新規案件登録",
    four_point_completed: "✅ 4点チェック完了",
    pre_construction_completed: "🔧 着工前ゲート完了",
    construction_started: "🚧 着工",
    project_completed: "🎉 完工",
    budget_confirmed: "💰 実行予算確定",
    daily_report_submitted: "📝 日報提出",
    daily_report_confirmed: "✔️ 日報確認",
    daily_report_reminder: "⏰ 日報リマインダー",
    invoice_issued: "📄 請求書発行",
    payment_received: "💵 入金確認",
    offset_confirmed: "🔄 相殺確定"
  }.freeze

  class << self
    delegate :notify, :project_created, :four_point_completed,
             :pre_construction_completed, :construction_started, :project_completed,
             :budget_confirmed, :daily_report_submitted, :daily_report_confirmed,
             :invoice_issued, :payment_received, :offset_confirmed,
             to: :instance
  end

  def initialize
    @n8n_webhook_url = ENV.fetch("N8N_WEBHOOK_URL", "http://sanyu-n8n:5678/webhook/lineworks")
    @direct_api_enabled = ENV.fetch("LINE_WORKS_BOT_ID", nil).present?
  end

  # 汎用通知メソッド
  def notify(type:, message:, data: {})
    return mock_response(type, message) unless enabled?

    payload = build_payload(type, message, data)
    send_to_n8n(payload)
  end

  # === 案件関連通知 ===

  def project_created(project)
    notify(
      type: :project_created,
      message: build_message(:project_created, [
        "案件名: #{project.name}",
        "顧客: #{project.client&.name || '未設定'}",
        "現場: #{project.site_address || '未設定'}"
      ]),
      data: {
        project_id: project.id,
        project_code: project.code,
        project_name: project.name,
        client_name: project.client&.name
      }
    )
  end

  def four_point_completed(project)
    notify(
      type: :four_point_completed,
      message: build_message(:four_point_completed, [
        "案件名: #{project.name}",
        "受注金額: #{format_currency(project.order_amount)}"
      ]),
      data: {
        project_id: project.id,
        project_code: project.code,
        order_amount: project.order_amount
      }
    )
  end

  def pre_construction_completed(project)
    notify(
      type: :pre_construction_completed,
      message: build_message(:pre_construction_completed, [
        "案件名: #{project.name}",
        "実行予算が確定し、着工準備が整いました"
      ]),
      data: {
        project_id: project.id,
        project_code: project.code
      }
    )
  end

  def construction_started(project)
    notify(
      type: :construction_started,
      message: build_message(:construction_started, [
        "案件名: #{project.name}",
        "着工日: #{project.construction_started_at&.strftime('%Y/%m/%d')}"
      ]),
      data: {
        project_id: project.id,
        project_code: project.code,
        started_at: project.construction_started_at
      }
    )
  end

  def project_completed(project)
    notify(
      type: :project_completed,
      message: build_message(:project_completed, [
        "案件名: #{project.name}",
        "完工日: #{project.completed_at&.strftime('%Y/%m/%d')}"
      ]),
      data: {
        project_id: project.id,
        project_code: project.code,
        completed_at: project.completed_at
      }
    )
  end

  # === 予算関連通知 ===

  def budget_confirmed(budget)
    notify(
      type: :budget_confirmed,
      message: build_message(:budget_confirmed, [
        "案件名: #{budget.project&.name}",
        "原価予算: #{format_currency(budget.total_cost)}",
        "目標利益率: #{budget.target_profit_rate}%"
      ]),
      data: {
        budget_id: budget.id,
        project_id: budget.project_id,
        total_cost: budget.total_cost
      }
    )
  end

  # === 日報関連通知 ===

  def daily_report_submitted(report)
    notify(
      type: :daily_report_submitted,
      message: build_message(:daily_report_submitted, [
        "案件: #{report.project&.name}",
        "日付: #{report.report_date}",
        "天気: #{report.weather}",
        "出面: #{report.attendances.count}名"
      ]),
      data: {
        daily_report_id: report.id,
        project_id: report.project_id,
        report_date: report.report_date
      }
    )
  end

  def daily_report_confirmed(report)
    notify(
      type: :daily_report_confirmed,
      message: build_message(:daily_report_confirmed, [
        "案件: #{report.project&.name}",
        "日付: #{report.report_date}",
        "確認者: #{report.confirmed_by&.name}"
      ]),
      data: {
        daily_report_id: report.id,
        project_id: report.project_id
      }
    )
  end

  # === 請求関連通知 ===

  def invoice_issued(invoice)
    notify(
      type: :invoice_issued,
      message: build_message(:invoice_issued, [
        "案件: #{invoice.project&.name}",
        "請求番号: #{invoice.invoice_number}",
        "請求額: #{format_currency(invoice.total_amount)}",
        "支払期限: #{invoice.due_date&.strftime('%Y/%m/%d')}"
      ]),
      data: {
        invoice_id: invoice.id,
        invoice_number: invoice.invoice_number,
        total_amount: invoice.total_amount
      }
    )
  end

  def payment_received(payment)
    invoice = payment.invoice
    notify(
      type: :payment_received,
      message: build_message(:payment_received, [
        "案件: #{invoice&.project&.name}",
        "入金額: #{format_currency(payment.amount)}",
        "残高: #{format_currency(invoice&.remaining_amount)}"
      ]),
      data: {
        payment_id: payment.id,
        invoice_id: invoice&.id,
        amount: payment.amount
      }
    )
  end

  # === 相殺関連通知 ===

  def offset_confirmed(offset)
    notify(
      type: :offset_confirmed,
      message: build_message(:offset_confirmed, [
        "協力会社: #{offset.partner&.name}",
        "対象月: #{offset.year_month}",
        "相殺額: #{format_currency(offset.offset_amount)}"
      ]),
      data: {
        offset_id: offset.id,
        partner_name: offset.partner&.name,
        offset_amount: offset.offset_amount
      }
    )
  end

  private

  def enabled?
    ENV.fetch("LINE_WORKS_NOTIFICATIONS_ENABLED", "true") == "true"
  end

  def build_message(type, lines)
    title = NOTIFICATION_TYPES[type] || type.to_s
    "#{title}\n\n#{lines.join("\n")}"
  end

  def build_payload(type, message, data)
    {
      event_type: type.to_s,
      type_label: NOTIFICATION_TYPES[type] || type.to_s,
      message: message,
      data: data,
      timestamp: Time.current.iso8601
    }
  end

  def send_to_n8n(payload)
    uri = URI.parse(@n8n_webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = http.request(request)

    if response.code.to_i.between?(200, 299)
      Rails.logger.info "[LineWorksNotifier] Sent: #{payload[:event_type]}"
      { success: true, response_code: response.code }
    else
      Rails.logger.warn "[LineWorksNotifier] Failed: #{response.code} - #{response.body}"
      { success: false, response_code: response.code, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error "[LineWorksNotifier] Error: #{e.message}"
    { success: false, error: e.message }
  end

  def mock_response(type, message)
    Rails.logger.info "[LineWorksNotifier Mock] #{type}: #{message.truncate(100)}"
    { success: true, mock: true, type: type }
  end

  def format_currency(amount)
    return "¥0" unless amount
    "¥#{amount.to_i.to_s(:delimited)}"
  end
end
