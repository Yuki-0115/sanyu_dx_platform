# frozen_string_literal: true

require "csv"

namespace :export do
  desc "請求書データをCSVでエクスポート"
  task invoices: :environment do
    filename = Rails.root.join("tmp", "invoices_#{Date.current.strftime('%Y%m%d')}.csv")

    CSV.open(filename, "w", encoding: "UTF-8") do |csv|
      csv << %w[請求番号 案件コード 案件名 顧客名 発行日 支払期日 税抜金額 消費税 合計 ステータス 入金済 残高]

      Invoice.includes(project: :client).order(created_at: :desc).each do |inv|
        csv << [
          inv.invoice_number,
          inv.project&.code,
          inv.project&.name,
          inv.project&.client&.name,
          inv.issued_date&.strftime("%Y-%m-%d"),
          inv.due_date&.strftime("%Y-%m-%d"),
          inv.amount.to_i,
          inv.tax_amount.to_i,
          inv.total_amount.to_i,
          inv.status,
          inv.paid_amount.to_i,
          (inv.total_amount.to_i - inv.paid_amount.to_i)
        ]
      end
    end

    puts "✅ エクスポート完了: #{filename}"
    puts "   件数: #{Invoice.count}件"
  end

  desc "経費データをCSVでエクスポート"
  task expenses: :environment do
    filename = Rails.root.join("tmp", "expenses_#{Date.current.strftime('%Y%m%d')}.csv")

    CSV.open(filename, "w", encoding: "UTF-8") do |csv|
      csv << %w[ID 案件コード 案件名 日付 カテゴリ 金額 支払方法 摘要 支払者 領収書 ステータス]

      Expense.includes(daily_report: :project, payer: nil).order(created_at: :desc).each do |exp|
        csv << [
          exp.id,
          exp.daily_report&.project&.code,
          exp.daily_report&.project&.name,
          exp.daily_report&.report_date&.strftime("%Y-%m-%d"),
          exp.category_label,
          exp.amount.to_i,
          exp.payment_method_label,
          exp.description,
          exp.payer&.name,
          exp.receipt_attached? ? "あり" : "なし",
          exp.status
        ]
      end
    end

    puts "✅ エクスポート完了: #{filename}"
    puts "   件数: #{Expense.count}件"
  end

  desc "案件データをCSVでエクスポート"
  task projects: :environment do
    filename = Rails.root.join("tmp", "projects_#{Date.current.strftime('%Y%m%d')}.csv")

    CSV.open(filename, "w", encoding: "UTF-8") do |csv|
      csv << %w[案件コード 案件名 顧客名 ステータス 受注金額 実績原価 粗利 粗利率 営業担当 工務担当 施工担当 予定開始 予定終了]

      Project.includes(:client, :sales_user, :engineering_user, :construction_user).order(created_at: :desc).each do |pj|
        csv << [
          pj.code,
          pj.name,
          pj.client&.name,
          pj.status,
          pj.order_amount.to_i,
          pj.actual_cost.to_i,
          pj.gross_profit.to_i,
          pj.profit_margin&.round(1),
          pj.sales_user&.name,
          pj.engineering_user&.name,
          pj.construction_user&.name,
          pj.scheduled_start_date&.strftime("%Y-%m-%d"),
          pj.scheduled_end_date&.strftime("%Y-%m-%d")
        ]
      end
    end

    puts "✅ エクスポート完了: #{filename}"
    puts "   件数: #{Project.count}件"
  end

  desc "日報データをCSVでエクスポート"
  task daily_reports: :environment do
    filename = Rails.root.join("tmp", "daily_reports_#{Date.current.strftime('%Y%m%d')}.csv")

    CSV.open(filename, "w", encoding: "UTF-8") do |csv|
      csv << %w[案件コード 案件名 日付 職長 天候 出面数 労務費 材料費 外注費 運搬費 燃料費 高速代 合計原価 作業内容 ステータス]

      DailyReport.includes(:project, :foreman, :attendances).order(report_date: :desc).each do |dr|
        csv << [
          dr.project&.code,
          dr.project&.name,
          dr.report_date&.strftime("%Y-%m-%d"),
          dr.foreman&.name,
          dr.weather,
          dr.attendances.size,
          dr.labor_cost.to_i,
          dr.material_cost.to_i,
          dr.outsourcing_cost.to_i,
          dr.transportation_cost.to_i,
          dr.fuel_amount.to_i,
          dr.highway_amount.to_i,
          dr.total_cost.to_i,
          dr.work_content,
          dr.status
        ]
      end
    end

    puts "✅ エクスポート完了: #{filename}"
    puts "   件数: #{DailyReport.count}件"
  end

  desc "全データをCSVでエクスポート"
  task all: :environment do
    puts "=" * 50
    puts "全データをCSVでエクスポート"
    puts "=" * 50
    puts ""

    Rake::Task["export:invoices"].invoke
    Rake::Task["export:expenses"].invoke
    Rake::Task["export:projects"].invoke
    Rake::Task["export:daily_reports"].invoke

    puts ""
    puts "=" * 50
    puts "エクスポート完了！"
    puts "ファイルは rails/platform/tmp/ にあります"
    puts "=" * 50
  end
end
