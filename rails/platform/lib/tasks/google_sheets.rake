# frozen_string_literal: true

namespace :google_sheets do
  desc "Google Sheets連携の状態確認"
  task status: :environment do
    puts "=" * 50
    puts "Google Sheets連携状況"
    puts "=" * 50

    spreadsheet_id = ENV.fetch("GOOGLE_SPREADSHEET_ID", nil)
    credentials_path = Rails.root.join("config", "google_service_account.json")

    puts ""
    puts "【設定状況】"
    puts "  SPREADSHEET_ID: #{spreadsheet_id.present? ? '設定済み' : '未設定'}"
    puts "  認証ファイル: #{File.exist?(credentials_path) ? '存在' : '未配置'}"
    puts ""

    if GoogleSheetsService.enabled?
      puts "  ステータス: ✅ 有効"
    else
      puts "  ステータス: ❌ 無効"
      puts ""
      puts "【セットアップ手順】"
      puts "1. Google Cloud Consoleでプロジェクトを作成"
      puts "2. Google Sheets APIを有効化"
      puts "3. サービスアカウントを作成し、JSONキーをダウンロード"
      puts "4. JSONファイルを config/google_service_account.json に配置"
      puts "5. スプレッドシートを作成し、サービスアカウントに共有"
      puts "6. 環境変数 GOOGLE_SPREADSHEET_ID にスプレッドシートIDを設定"
    end
    puts ""
  end

  desc "スプレッドシートのシートを初期化（ヘッダー作成）"
  task init: :environment do
    unless GoogleSheetsService.enabled?
      puts "❌ Google Sheets連携が有効ではありません"
      puts "   rake google_sheets:status で設定状況を確認してください"
      exit 1
    end

    puts "スプレッドシートを初期化しています..."
    result = GoogleSheetsService.create_sheets_if_not_exist

    if result[:success]
      puts "✅ 初期化完了"
      puts "   作成されたシート:"
      puts "   - 請求書一覧"
      puts "   - 入金一覧"
      puts "   - 経費一覧"
      puts "   - 案件一覧"
      puts "   - 日報一覧"
    else
      puts "❌ エラー: #{result[:error]}"
    end
  end

  desc "全請求書データをスプレッドシートに同期"
  task sync_invoices: :environment do
    unless GoogleSheetsService.enabled?
      puts "❌ Google Sheets連携が有効ではありません"
      exit 1
    end

    puts "請求書データを同期しています..."
    result = GoogleSheetsService.sync_all_invoices

    if result[:success]
      puts "✅ 同期完了: #{result[:count]}件"
    else
      puts "❌ エラー: #{result[:error]}"
    end
  end

  desc "全経費データをスプレッドシートに同期"
  task sync_expenses: :environment do
    unless GoogleSheetsService.enabled?
      puts "❌ Google Sheets連携が有効ではありません"
      exit 1
    end

    puts "経費データを同期しています..."
    result = GoogleSheetsService.sync_all_expenses

    if result[:success]
      puts "✅ 同期完了: #{result[:count]}件"
    else
      puts "❌ エラー: #{result[:error]}"
    end
  end

  desc "全案件データをスプレッドシートに同期"
  task sync_projects: :environment do
    unless GoogleSheetsService.enabled?
      puts "❌ Google Sheets連携が有効ではありません"
      exit 1
    end

    puts "案件データを同期しています..."

    # ヘッダー設定
    count = 0
    Project.includes(:client, :sales_user, :engineering_user, :construction_user).find_each do |project|
      GoogleSheetsService.append_project(project)
      count += 1
      print "." if (count % 10).zero?
    end

    puts ""
    puts "✅ 同期完了: #{count}件"
  end

  desc "全日報データをスプレッドシートに同期"
  task sync_daily_reports: :environment do
    unless GoogleSheetsService.enabled?
      puts "❌ Google Sheets連携が有効ではありません"
      exit 1
    end

    puts "日報データを同期しています..."

    count = 0
    DailyReport.includes(:project, :foreman, :attendances).find_each do |report|
      GoogleSheetsService.append_daily_report(report)
      count += 1
      print "." if (count % 10).zero?
    end

    puts ""
    puts "✅ 同期完了: #{count}件"
  end

  desc "全データをスプレッドシートに同期"
  task sync_all: :environment do
    Rake::Task["google_sheets:init"].invoke
    Rake::Task["google_sheets:sync_invoices"].invoke
    Rake::Task["google_sheets:sync_expenses"].invoke
    Rake::Task["google_sheets:sync_projects"].invoke
    Rake::Task["google_sheets:sync_daily_reports"].invoke

    puts ""
    puts "=" * 50
    puts "✅ 全データの同期が完了しました"
    puts "=" * 50
  end

  desc "テストデータをスプレッドシートに送信（デモ用）"
  task demo: :environment do
    puts "=" * 50
    puts "デモ: スプレッドシートへのデータ送信テスト"
    puts "=" * 50
    puts ""

    # 最新の請求書を取得
    invoice = Invoice.includes(project: :client).order(created_at: :desc).first
    if invoice
      puts "【請求書データ】"
      puts "  請求番号: #{invoice.invoice_number}"
      puts "  案件: #{invoice.project&.name}"
      puts "  顧客: #{invoice.project&.client&.name}"
      puts "  金額: ¥#{invoice.total_amount.to_i.to_fs(:delimited)}"
      puts ""

      if GoogleSheetsService.enabled?
        result = GoogleSheetsService.append_invoice(invoice)
        puts result[:success] ? "  ✅ スプレッドシートに送信成功" : "  ❌ エラー: #{result[:error]}"
      else
        puts "  ⚠️ Google Sheets未設定のため送信スキップ"
      end
    else
      puts "請求書データがありません"
    end

    puts ""

    # 最新の経費を取得
    expense = Expense.includes(daily_report: :project, payer: nil).order(created_at: :desc).first
    if expense
      puts "【経費データ】"
      puts "  案件: #{expense.daily_report&.project&.name}"
      puts "  日付: #{expense.daily_report&.report_date}"
      puts "  カテゴリ: #{expense.category_label}"
      puts "  金額: ¥#{expense.amount.to_i.to_fs(:delimited)}"
      puts ""

      if GoogleSheetsService.enabled?
        result = GoogleSheetsService.append_expense(expense)
        puts result[:success] ? "  ✅ スプレッドシートに送信成功" : "  ❌ エラー: #{result[:error]}"
      else
        puts "  ⚠️ Google Sheets未設定のため送信スキップ"
      end
    else
      puts "経費データがありません"
    end

    puts ""
    puts "=" * 50
  end
end
