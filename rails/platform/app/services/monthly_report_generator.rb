# frozen_string_literal: true

require "csv"

# 月次帳票生成サービス
# - 月次原価集計
# - 案件別利益一覧
# - 経費精算一覧
# Google Driveへ自動保存
class MonthlyReportGenerator
  include Singleton

  class << self
    delegate :generate_all, :generate_cost_report, :generate_profit_report,
             :generate_expense_report, to: :instance
  end

  # 指定月の全帳票を生成してDriveにアップロード
  def generate_all(year:, month:)
    return { success: false, error: "Google Drive not configured" } unless GoogleDriveService.enabled?

    # 月次フォルダを作成
    folder_result = GoogleDriveService.create_monthly_report_folder(year, month)
    return { success: false, error: "Failed to create folder" } unless folder_result

    folder_id = folder_result[:folder_id]
    results = {}

    # 各帳票を生成してアップロード
    results[:cost_report] = upload_report(
      generate_cost_report(year: year, month: month),
      "原価集計_#{year}#{month.to_s.rjust(2, '0')}.csv",
      folder_id
    )

    results[:profit_report] = upload_report(
      generate_profit_report(year: year, month: month),
      "案件別利益_#{year}#{month.to_s.rjust(2, '0')}.csv",
      folder_id
    )

    results[:expense_report] = upload_report(
      generate_expense_report(year: year, month: month),
      "経費精算_#{year}#{month.to_s.rjust(2, '0')}.csv",
      folder_id
    )

    {
      success: true,
      folder_url: folder_result[:folder_url],
      reports: results
    }
  end

  # 原価集計レポート（CSV）
  def generate_cost_report(year:, month:)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    projects = Project.active.includes(:daily_reports, :budget)

    CSV.generate(encoding: "UTF-8", write_headers: true,
                 headers: %w[案件コード 案件名 顧客 受注金額 予算原価 実績原価 粗利 利益率]) do |csv|
      projects.each do |project|
        # 当月の日報から実績を集計
        monthly_reports = project.daily_reports
                                 .where(report_date: start_date..end_date)
                                 .where(status: %w[confirmed revised])

        next if monthly_reports.empty? && project.budget.blank?

        monthly_cost = monthly_reports.sum { |r| r.total_cost.to_i }
        budget_cost = project.budget&.total_cost.to_i
        order_amount = project.order_amount.to_i
        gross_profit = order_amount - monthly_cost
        profit_rate = order_amount.positive? ? (gross_profit.to_f / order_amount * 100).round(1) : 0

        csv << [
          project.code,
          project.name,
          project.client&.name,
          order_amount,
          budget_cost,
          monthly_cost,
          gross_profit,
          "#{profit_rate}%"
        ]
      end
    end
  end

  # 案件別利益レポート（CSV）
  def generate_profit_report(year:, month:)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    projects = Project.where(status: %w[in_progress completed invoiced paid])
                      .includes(:client, :budget)

    CSV.generate(encoding: "UTF-8", write_headers: true,
                 headers: %w[案件コード 案件名 顧客 ステータス 受注金額 累計原価 粗利額 利益率 出来高 進捗率]) do |csv|
      projects.each do |project|
        order_amount = project.order_amount.to_i
        actual_cost = project.site_ledger_total_cost
        gross_profit = order_amount - actual_cost
        profit_rate = order_amount.positive? ? (gross_profit.to_f / order_amount * 100).round(1) : 0
        progress = project.cumulative_progress_amount
        progress_rate = project.progress_rate || 0

        csv << [
          project.code,
          project.name,
          project.client&.name,
          project.status,
          order_amount,
          actual_cost,
          gross_profit,
          "#{profit_rate}%",
          progress,
          "#{progress_rate}%"
        ]
      end
    end
  end

  # 経費精算レポート（CSV）
  def generate_expense_report(year:, month:)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    expenses = Expense.where(expense_date: start_date..end_date)
                      .where(status: "approved")
                      .includes(:payer, :project)
                      .order(:expense_date)

    CSV.generate(encoding: "UTF-8", write_headers: true,
                 headers: %w[日付 申請者 案件 カテゴリ 支払方法 金額 勘定科目 税区分 経理処理]) do |csv|
      expenses.each do |expense|
        csv << [
          expense.expense_date&.strftime("%Y/%m/%d"),
          expense.payer&.name,
          expense.project&.name,
          expense.category_label,
          expense.payment_method_label,
          expense.amount,
          expense.account_code,
          expense.tax_category,
          expense.accounting_status == "processed" ? "処理済" : "未処理"
        ]
      end
    end
  end

  private

  def upload_report(csv_content, filename, folder_id)
    # 一時ファイルに保存
    temp_file = Tempfile.new([filename, ".csv"])
    temp_file.write("\xEF\xBB\xBF") # BOM for Excel
    temp_file.write(csv_content)
    temp_file.close

    result = GoogleDriveService.instance.send(:upload_file,
      file_path: temp_file.path,
      file_name: filename,
      folder_id: folder_id,
      mime_type: "text/csv"
    )

    temp_file.unlink
    result
  rescue StandardError => e
    Rails.logger.error "[MonthlyReportGenerator] Error: #{e.message}"
    nil
  end
end
