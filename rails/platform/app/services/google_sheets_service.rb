# frozen_string_literal: true

require "google/apis/sheets_v4"
require "googleauth"

# Google Sheets連携サービス
# 請求書・領収書データをスプレッドシートに記録
class GoogleSheetsService
  include Singleton

  # スプレッドシートID（環境変数から取得）
  SPREADSHEET_ID = ENV.fetch("GOOGLE_SPREADSHEET_ID", nil)

  # サービスアカウントの認証情報ファイルパス
  CREDENTIALS_PATH = Rails.root.join("config", "google_service_account.json")

  # シート名
  SHEETS = {
    invoices: "請求書一覧",
    payments: "入金一覧",
    expenses: "経費一覧",
    projects: "案件一覧",
    daily_reports: "日報一覧"
  }.freeze

  class << self
    delegate :enabled?, :append_invoice, :append_payment, :append_expense,
             :append_project, :append_daily_report, :sync_all_invoices,
             :sync_all_expenses, :create_sheets_if_not_exist,
             to: :instance
  end

  def initialize
    @service = nil
  end

  def enabled?
    SPREADSHEET_ID.present? && File.exist?(CREDENTIALS_PATH)
  end

  # ========================================
  # 請求書データの追加
  # ========================================
  def append_invoice(invoice)
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    row = [
      invoice.invoice_number,
      invoice.project&.code,
      invoice.project&.name,
      invoice.project&.client&.name,
      invoice.issued_date&.strftime("%Y-%m-%d"),
      invoice.due_date&.strftime("%Y-%m-%d"),
      invoice.amount.to_i,
      invoice.tax_amount.to_i,
      invoice.total_amount.to_i,
      invoice.status,
      invoice.paid_amount.to_i,
      (invoice.total_amount.to_i - invoice.paid_amount.to_i),
      Time.current.strftime("%Y-%m-%d %H:%M:%S")
    ]

    append_row(SHEETS[:invoices], row)
  end

  # ========================================
  # 入金データの追加
  # ========================================
  def append_payment(payment)
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    row = [
      payment.invoice&.invoice_number,
      payment.invoice&.project&.code,
      payment.invoice&.project&.name,
      payment.payment_date&.strftime("%Y-%m-%d"),
      payment.amount.to_i,
      payment.note,
      Time.current.strftime("%Y-%m-%d %H:%M:%S")
    ]

    append_row(SHEETS[:payments], row)
  end

  # ========================================
  # 経費データの追加
  # ========================================
  def append_expense(expense)
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    row = [
      expense.id,
      expense.daily_report&.project&.code,
      expense.daily_report&.project&.name,
      expense.daily_report&.report_date&.strftime("%Y-%m-%d"),
      expense.category_label,
      expense.amount.to_i,
      expense.payment_method_label,
      expense.description,
      expense.payer&.name,
      expense.receipt_attached? ? "あり" : "なし",
      expense.status,
      Time.current.strftime("%Y-%m-%d %H:%M:%S")
    ]

    append_row(SHEETS[:expenses], row)
  end

  # ========================================
  # 案件データの追加
  # ========================================
  def append_project(project)
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    row = [
      project.code,
      project.name,
      project.client&.name,
      project.status,
      project.order_amount.to_i,
      project.actual_cost.to_i,
      project.gross_profit.to_i,
      project.profit_margin&.round(1),
      project.sales_user&.name,
      project.engineering_user&.name,
      project.construction_user&.name,
      project.scheduled_start_date&.strftime("%Y-%m-%d"),
      project.scheduled_end_date&.strftime("%Y-%m-%d"),
      Time.current.strftime("%Y-%m-%d %H:%M:%S")
    ]

    append_row(SHEETS[:projects], row)
  end

  # ========================================
  # 日報データの追加
  # ========================================
  def append_daily_report(daily_report)
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    row = [
      daily_report.project&.code,
      daily_report.project&.name,
      daily_report.report_date&.strftime("%Y-%m-%d"),
      daily_report.foreman&.name,
      daily_report.weather_label,
      daily_report.attendances.size,
      daily_report.labor_cost.to_i,
      daily_report.material_cost.to_i,
      daily_report.outsourcing_cost.to_i,
      daily_report.total_cost.to_i,
      daily_report.work_content,
      daily_report.status,
      Time.current.strftime("%Y-%m-%d %H:%M:%S")
    ]

    append_row(SHEETS[:daily_reports], row)
  end

  # ========================================
  # 全データの同期（初回または再同期用）
  # ========================================
  def sync_all_invoices
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    # ヘッダー行を作成
    headers = %w[請求番号 案件コード 案件名 顧客名 請求日 支払期日 小計 消費税 合計 ステータス 入金済 残高 更新日時]
    clear_and_set_headers(SHEETS[:invoices], headers)

    # 全請求書を追加
    Invoice.includes(project: :client).find_each do |invoice|
      append_invoice(invoice)
    end

    { success: true, count: Invoice.count }
  end

  def sync_all_expenses
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    # ヘッダー行を作成
    headers = %w[ID 案件コード 案件名 日付 カテゴリ 金額 支払方法 摘要 支払者 領収書 ステータス 更新日時]
    clear_and_set_headers(SHEETS[:expenses], headers)

    # 全経費を追加
    Expense.includes(daily_report: :project, payer: nil).find_each do |expense|
      append_expense(expense)
    end

    { success: true, count: Expense.count }
  end

  # ========================================
  # シートの初期化（ヘッダー作成）
  # ========================================
  def create_sheets_if_not_exist
    return { success: false, error: "Google Sheets not configured" } unless enabled?

    sheet_configs = {
      SHEETS[:invoices] => %w[請求番号 案件コード 案件名 顧客名 請求日 支払期日 小計 消費税 合計 ステータス 入金済 残高 更新日時],
      SHEETS[:payments] => %w[請求番号 案件コード 案件名 入金日 入金額 備考 更新日時],
      SHEETS[:expenses] => %w[ID 案件コード 案件名 日付 カテゴリ 金額 支払方法 摘要 支払者 領収書 ステータス 更新日時],
      SHEETS[:projects] => %w[案件コード 案件名 顧客名 ステータス 受注金額 実績原価 粗利 粗利率 営業担当 工務担当 施工担当 予定開始 予定終了 更新日時],
      SHEETS[:daily_reports] => %w[案件コード 案件名 日付 職長 天候 出面数 労務費 材料費 外注費 合計原価 作業内容 ステータス 更新日時]
    }

    sheet_configs.each do |sheet_name, headers|
      ensure_sheet_exists(sheet_name)
      set_headers(sheet_name, headers)
    end

    { success: true }
  end

  private

  def service
    @service ||= begin
      s = Google::Apis::SheetsV4::SheetsService.new
      s.authorization = authorize
      s
    end
  end

  def authorize
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(CREDENTIALS_PATH),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
  end

  def append_row(sheet_name, values)
    range = "#{sheet_name}!A:Z"
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: [values])

    service.append_spreadsheet_value(
      SPREADSHEET_ID,
      range,
      value_range,
      value_input_option: "USER_ENTERED"
    )

    Rails.logger.info "[GoogleSheets] Row appended to #{sheet_name}"
    { success: true }
  rescue StandardError => e
    Rails.logger.error "[GoogleSheets] Error appending row: #{e.message}"
    { success: false, error: e.message }
  end

  def clear_and_set_headers(sheet_name, headers)
    range = "#{sheet_name}!A:Z"
    service.clear_values(SPREADSHEET_ID, range)
    set_headers(sheet_name, headers)
  end

  def set_headers(sheet_name, headers)
    range = "#{sheet_name}!A1:Z1"
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: [headers])

    service.update_spreadsheet_value(
      SPREADSHEET_ID,
      range,
      value_range,
      value_input_option: "USER_ENTERED"
    )
  end

  def ensure_sheet_exists(sheet_name)
    spreadsheet = service.get_spreadsheet(SPREADSHEET_ID)
    sheet_exists = spreadsheet.sheets.any? { |s| s.properties.title == sheet_name }

    return if sheet_exists

    request = Google::Apis::SheetsV4::AddSheetRequest.new(
      properties: Google::Apis::SheetsV4::SheetProperties.new(title: sheet_name)
    )

    batch_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
      requests: [{ add_sheet: request }]
    )

    service.batch_update_spreadsheet(SPREADSHEET_ID, batch_request)
  end
end
