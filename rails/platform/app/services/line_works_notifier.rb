# frozen_string_literal: true

# LINE WORKS Bot API を使用した通知サービス
# n8n経由で呼び出すか、直接呼び出すことが可能
class LineWorksNotifier
  NOTIFICATION_TYPES = {
    project_created: "新規案件登録",
    four_point_completed: "4点チェック完了",
    budget_confirmed: "実行予算確定",
    daily_report_submitted: "日報提出",
    daily_report_reminder: "日報リマインダー",
    offset_confirmed: "相殺確定"
  }.freeze

  def initialize
    @bot_id = ENV.fetch("LINE_WORKS_BOT_ID", nil)
    @api_url = ENV.fetch("LINE_WORKS_API_URL", nil)
    @enabled = @bot_id.present? && @api_url.present?
  end

  def notify(type:, message:, recipients: [], data: {})
    return mock_response(type, message) unless @enabled

    payload = build_payload(type, message, data)
    send_notification(payload, recipients)
  end

  def notify_project_created(project)
    notify(
      type: :project_created,
      message: "新規案件が登録されました\n案件名: #{project.name}\n顧客: #{project.client&.name}",
      data: { project_id: project.id, project_code: project.code }
    )
  end

  def notify_four_point_completed(project)
    notify(
      type: :four_point_completed,
      message: "4点チェックが完了しました\n案件名: #{project.name}\n受注金額: #{format_currency(project.order_amount)}",
      data: { project_id: project.id }
    )
  end

  def notify_budget_confirmed(budget)
    notify(
      type: :budget_confirmed,
      message: "実行予算が確定しました\n案件名: #{budget.project&.name}\n予算額: #{format_currency(budget.total_cost)}",
      data: { budget_id: budget.id, project_id: budget.project_id }
    )
  end

  def notify_daily_report_submitted(daily_report)
    notify(
      type: :daily_report_submitted,
      message: "日報が提出されました\n案件名: #{daily_report.project&.name}\n日付: #{daily_report.report_date}",
      data: { daily_report_id: daily_report.id }
    )
  end

  def notify_daily_report_reminder(project, missing_date)
    notify(
      type: :daily_report_reminder,
      message: "日報が未提出です\n案件名: #{project.name}\n対象日: #{missing_date}",
      data: { project_id: project.id, missing_date: missing_date }
    )
  end

  def notify_offset_confirmed(offset)
    notify(
      type: :offset_confirmed,
      message: "相殺が確定しました\n協力会社: #{offset.partner&.name}\n対象月: #{offset.year_month}\n相殺額: #{format_currency(offset.offset_amount)}",
      data: { offset_id: offset.id }
    )
  end

  private

  def build_payload(type, message, data)
    {
      type: type.to_s,
      type_label: NOTIFICATION_TYPES[type] || type.to_s,
      message: message,
      data: data,
      timestamp: Time.current.iso8601
    }
  end

  def send_notification(payload, recipients)
    # LINE WORKS Bot API への送信
    # 実際の実装では Net::HTTP や Faraday を使用
    uri = URI.parse("#{@api_url}/messages")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{access_token}"
    request.body = {
      botId: @bot_id,
      content: {
        type: "text",
        text: payload[:message]
      },
      recipients: recipients
    }.to_json

    response = http.request(request)
    { success: response.code == "200", response: response.body }
  rescue StandardError => e
    Rails.logger.error("LINE WORKS notification failed: #{e.message}")
    { success: false, error: e.message }
  end

  def access_token
    # LINE WORKS OAuth トークン取得
    # 本番実装では適切なトークン管理を行う
    ENV.fetch("LINE_WORKS_ACCESS_TOKEN", "")
  end

  def mock_response(type, message)
    Rails.logger.info("[LINE WORKS Mock] Type: #{type}, Message: #{message}")
    { success: true, mock: true, type: type, message: message }
  end

  def format_currency(amount)
    return "¥0" unless amount

    "¥#{amount.to_i.to_s(:delimited)}"
  end
end
