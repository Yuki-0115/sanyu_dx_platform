# frozen_string_literal: true

require "jwt"
require "net/http"
require "uri"
require "json"

# LINE WORKS通知サービス
# Bot APIを使用してメッセージを送信
class LineWorksNotifier
  include Singleton

  TOKEN_URL = "https://auth.worksmobile.com/oauth2/v2.0/token"
  BOT_API_URL = "https://www.worksapis.com/v1.0/bots"

  NOTIFICATION_TYPES = {
    project_created: "新規案件登録",
    four_point_completed: "4点チェック完了",
    pre_construction_completed: "着工前ゲート完了",
    construction_started: "着工",
    project_completed: "完工",
    budget_confirmed: "実行予算確定",
    daily_report_submitted: "日報提出",
    daily_report_confirmed: "日報確認",
    invoice_issued: "請求書発行",
    payment_received: "入金確認",
    offset_confirmed: "相殺確定"
  }.freeze

  class << self
    delegate :notify, :project_created, :four_point_completed,
             :pre_construction_completed, :construction_started, :project_completed,
             :budget_confirmed, :daily_report_submitted, :daily_report_confirmed,
             :invoice_issued, :payment_received, :offset_confirmed,
             :test_connection, :send_test_message,
             to: :instance
  end

  def initialize
    @bot_id = ENV.fetch("LINE_WORKS_BOT_ID", nil)
    @client_id = ENV.fetch("LINE_WORKS_CLIENT_ID", nil)
    @client_secret = ENV.fetch("LINE_WORKS_CLIENT_SECRET", nil)
    @service_account = ENV.fetch("LINE_WORKS_SERVICE_ACCOUNT", nil)
    @private_key_path = ENV.fetch("LINE_WORKS_PRIVATE_KEY_PATH", nil)
    @notify_user_id = ENV.fetch("LINE_WORKS_NOTIFY_USER_ID", nil)
    @access_token = nil
    @token_expires_at = nil
  end

  # 汎用通知メソッド
  def notify(type:, message:, data: {})
    return mock_response(type, message) unless enabled?

    send_message(message)
  end

  # 接続テスト
  def test_connection
    return { success: false, error: "通知が無効です", enabled: false } unless enabled?

    token = get_access_token
    if token
      { success: true, message: "トークン取得成功" }
    else
      { success: false, error: "トークン取得失敗" }
    end
  end

  # テストメッセージ送信
  def send_test_message(custom_message = nil)
    message = custom_message || "[テスト通知]\n\nSanyuTech DX Platform からのテスト通知です。\n送信日時: #{Time.current.strftime('%Y/%m/%d %H:%M:%S')}"

    return mock_response(:test, message) unless enabled?

    send_message(message)
  end

  # === 案件関連通知 ===

  def project_created(project)
    notify(
      type: :project_created,
      message: build_message(:project_created, [
        "案件名: #{project.name}",
        "顧客: #{project.client&.name || '未設定'}",
        "現場: #{project.site_address || '未設定'}"
      ])
    )
  end

  def four_point_completed(project)
    notify(
      type: :four_point_completed,
      message: build_message(:four_point_completed, [
        "案件名: #{project.name}",
        "受注金額: #{format_currency(project.order_amount)}"
      ])
    )
  end

  def pre_construction_completed(project)
    notify(
      type: :pre_construction_completed,
      message: build_message(:pre_construction_completed, [
        "案件名: #{project.name}",
        "実行予算が確定し、着工準備が整いました"
      ])
    )
  end

  def construction_started(project)
    notify(
      type: :construction_started,
      message: build_message(:construction_started, [
        "案件名: #{project.name}",
        "着工日: #{project.actual_start_date&.strftime('%Y/%m/%d') || '未設定'}"
      ])
    )
  end

  def project_completed(project)
    notify(
      type: :project_completed,
      message: build_message(:project_completed, [
        "案件名: #{project.name}",
        "完工日: #{project.actual_end_date&.strftime('%Y/%m/%d') || '未設定'}"
      ])
    )
  end

  # === 予算関連通知 ===

  def budget_confirmed(budget)
    notify(
      type: :budget_confirmed,
      message: build_message(:budget_confirmed, [
        "案件名: #{budget.project&.name}",
        "原価予算: #{format_currency(budget.total_cost)}"
      ])
    )
  end

  # === 日報関連通知 ===

  def daily_report_submitted(report)
    notify(
      type: :daily_report_submitted,
      message: build_message(:daily_report_submitted, [
        "案件: #{report.project&.name}",
        "日付: #{report.report_date}",
        "出面: #{report.attendances.count}名"
      ])
    )
  end

  def daily_report_confirmed(report)
    notify(
      type: :daily_report_confirmed,
      message: build_message(:daily_report_confirmed, [
        "案件: #{report.project&.name || report.external_site_name || '外部現場'}",
        "日付: #{report.report_date}",
        "職長: #{report.foreman&.name || '不明'}"
      ])
    )
  end

  # === 請求関連通知 ===

  def invoice_issued(invoice)
    notify(
      type: :invoice_issued,
      message: build_message(:invoice_issued, [
        "案件: #{invoice.project&.name}",
        "請求番号: #{invoice.invoice_number}",
        "請求額: #{format_currency(invoice.total_amount)}"
      ])
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
      ])
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
      ])
    )
  end

  private

  def enabled?
    return false unless ENV.fetch("LINE_WORKS_NOTIFICATIONS_ENABLED", "true") == "true"

    @bot_id.present? && @client_id.present? && @service_account.present? && @private_key_path.present?
  end

  def build_message(type, lines)
    title = NOTIFICATION_TYPES[type] || type.to_s
    "[#{title}]\n\n#{lines.join("\n")}"
  end

  def send_message(message)
    token = get_access_token
    return { success: false, error: "Failed to get access token" } unless token

    uri = URI.parse("#{BOT_API_URL}/#{@bot_id}/users/#{@notify_user_id}/messages")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{token}"
    request.body = {
      content: {
        type: "text",
        text: message
      }
    }.to_json

    response = http.request(request)

    if response.code.to_i.between?(200, 299)
      Rails.logger.info "[LineWorksNotifier] Message sent successfully"
      { success: true, response_code: response.code }
    else
      Rails.logger.warn "[LineWorksNotifier] Failed: #{response.code} - #{response.body}"
      { success: false, response_code: response.code, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error "[LineWorksNotifier] Error: #{e.message}"
    { success: false, error: e.message }
  end

  def get_access_token
    # キャッシュされたトークンが有効ならそれを使う
    if @access_token && @token_expires_at && Time.current < @token_expires_at
      return @access_token
    end

    jwt = generate_jwt
    return nil unless jwt

    uri = URI.parse(TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/x-www-form-urlencoded"
    request.body = URI.encode_www_form(
      assertion: jwt,
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      client_id: @client_id,
      client_secret: @client_secret,
      scope: "bot"
    )

    response = http.request(request)

    if response.code.to_i == 200
      data = JSON.parse(response.body)
      @access_token = data["access_token"]
      @token_expires_at = Time.current + (data["expires_in"].to_i - 60).seconds
      Rails.logger.info "[LineWorksNotifier] Access token obtained"
      @access_token
    else
      Rails.logger.error "[LineWorksNotifier] Token error: #{response.code} - #{response.body}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[LineWorksNotifier] Token error: #{e.message}"
    nil
  end

  def generate_jwt
    return nil unless File.exist?(@private_key_path)

    private_key = OpenSSL::PKey::RSA.new(File.read(@private_key_path))

    payload = {
      iss: @client_id,
      sub: @service_account,
      iat: Time.current.to_i,
      exp: Time.current.to_i + 3600
    }

    JWT.encode(payload, private_key, "RS256")
  rescue StandardError => e
    Rails.logger.error "[LineWorksNotifier] JWT error: #{e.message}"
    nil
  end

  def mock_response(type, message)
    Rails.logger.info "[LineWorksNotifier Mock] #{type}: #{message.truncate(100)}"
    { success: true, mock: true, type: type }
  end

  def format_currency(amount)
    return "¥0" unless amount

    "¥#{amount.to_i.to_fs(:delimited)}"
  end
end
