# frozen_string_literal: true

namespace :notifications do
  desc "全LINE WORKS通知イベントをテスト送信"
  task test_all: :environment do
    puts "=" * 60
    puts "LINE WORKS通知テスト"
    puts "=" * 60
    puts

    results = []

    # 1. project_created
    results << test_notification("project_created", "案件登録") do
      project = Project.last
      if project
        NotificationJob.perform_now(
          event_type: "project_created",
          record_type: "Project",
          record_id: project.id
        )
      else
        puts "  ⚠️  案件データがありません"
        nil
      end
    end

    # 2. four_point_completed
    results << test_notification("four_point_completed", "4点チェック完了") do
      project = Project.where.not(four_point_completed_at: nil).last || Project.last
      if project
        NotificationJob.perform_now(
          event_type: "four_point_completed",
          record_type: "Project",
          record_id: project.id
        )
      else
        puts "  ⚠️  案件データがありません"
        nil
      end
    end

    # 3. pre_construction_completed
    results << test_notification("pre_construction_completed", "着工前ゲート完了") do
      project = Project.where.not(pre_construction_gate_completed_at: nil).last || Project.last
      if project
        NotificationJob.perform_now(
          event_type: "pre_construction_completed",
          record_type: "Project",
          record_id: project.id
        )
      else
        puts "  ⚠️  案件データがありません"
        nil
      end
    end

    # 4. construction_started
    results << test_notification("construction_started", "着工開始") do
      project = Project.where(status: "in_progress").last || Project.last
      if project
        NotificationJob.perform_now(
          event_type: "construction_started",
          record_type: "Project",
          record_id: project.id
        )
      else
        puts "  ⚠️  案件データがありません"
        nil
      end
    end

    # 5. project_completed
    results << test_notification("project_completed", "完工") do
      project = Project.where(status: "completed").last || Project.last
      if project
        NotificationJob.perform_now(
          event_type: "project_completed",
          record_type: "Project",
          record_id: project.id
        )
      else
        puts "  ⚠️  案件データがありません"
        nil
      end
    end

    # 6. budget_confirmed
    results << test_notification("budget_confirmed", "実行予算確定") do
      budget = Budget.where(status: "confirmed").last || Budget.last
      if budget
        NotificationJob.perform_now(
          event_type: "budget_confirmed",
          record_type: "Budget",
          record_id: budget.id
        )
      else
        puts "  ⚠️  予算データがありません"
        nil
      end
    end

    # 7. daily_report_submitted
    results << test_notification("daily_report_submitted", "日報提出") do
      daily_report = DailyReport.last
      if daily_report
        NotificationJob.perform_now(
          event_type: "daily_report_submitted",
          record_type: "DailyReport",
          record_id: daily_report.id
        )
      else
        puts "  ⚠️  日報データがありません"
        nil
      end
    end

    # 8. daily_report_confirmed
    results << test_notification("daily_report_confirmed", "日報確定") do
      daily_report = DailyReport.where(status: "confirmed").last || DailyReport.last
      if daily_report
        NotificationJob.perform_now(
          event_type: "daily_report_confirmed",
          record_type: "DailyReport",
          record_id: daily_report.id
        )
      else
        puts "  ⚠️  日報データがありません"
        nil
      end
    end

    # 9. invoice_issued
    results << test_notification("invoice_issued", "請求書発行") do
      invoice = Invoice.where(status: "issued").last || Invoice.last
      if invoice
        NotificationJob.perform_now(
          event_type: "invoice_issued",
          record_type: "Invoice",
          record_id: invoice.id
        )
      else
        puts "  ⚠️  請求書データがありません"
        nil
      end
    end

    # 10. payment_received
    results << test_notification("payment_received", "入金確認") do
      payment = Payment.last
      if payment
        NotificationJob.perform_now(
          event_type: "payment_received",
          record_type: "Payment",
          record_id: payment.id
        )
      else
        puts "  ⚠️  入金データがありません"
        nil
      end
    end

    # 11. offset_confirmed
    results << test_notification("offset_confirmed", "相殺確定") do
      offset = Offset.where(status: "confirmed").last || Offset.last
      if offset
        NotificationJob.perform_now(
          event_type: "offset_confirmed",
          record_type: "Offset",
          record_id: offset.id
        )
      else
        puts "  ⚠️  相殺データがありません"
        nil
      end
    end

    # 結果サマリー
    puts
    puts "=" * 60
    puts "テスト結果サマリー"
    puts "=" * 60
    success_count = results.count { |r| r == :success }
    skip_count = results.count { |r| r == :skipped }
    error_count = results.count { |r| r == :error }

    puts "  ✅ 成功: #{success_count}"
    puts "  ⏭️  スキップ: #{skip_count}"
    puts "  ❌ エラー: #{error_count}"
    puts
  end

  desc "特定のイベントをテスト送信 (event=event_type)"
  task test: :environment do
    event_type = ENV["event"]
    unless event_type
      puts "使用方法: bin/rails notifications:test event=project_created"
      puts
      puts "利用可能なイベント:"
      puts "  - project_created"
      puts "  - four_point_completed"
      puts "  - pre_construction_completed"
      puts "  - construction_started"
      puts "  - project_completed"
      puts "  - budget_confirmed"
      puts "  - daily_report_submitted"
      puts "  - daily_report_confirmed"
      puts "  - invoice_issued"
      puts "  - payment_received"
      puts "  - offset_confirmed"
      exit 1
    end

    record_type = ENV["record_type"] || infer_record_type(event_type)
    record_id = ENV["record_id"] || find_sample_record_id(event_type, record_type)

    unless record_id
      puts "❌ テスト用のレコードが見つかりません"
      exit 1
    end

    puts "通知テスト: #{event_type}"
    puts "  Record: #{record_type}##{record_id}"
    puts

    begin
      NotificationJob.perform_now(
        event_type: event_type,
        record_type: record_type,
        record_id: record_id.to_i
      )
      puts "✅ 通知送信完了"
    rescue => e
      puts "❌ エラー: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end
  end

  desc "LINE WORKS接続テスト"
  task connection_test: :environment do
    puts "LINE WORKS接続テスト"
    puts "=" * 40

    # 環境変数チェック
    required_vars = %w[
      LINE_WORKS_BOT_ID
      LINE_WORKS_CLIENT_ID
      LINE_WORKS_CLIENT_SECRET
      LINE_WORKS_SERVICE_ACCOUNT
      LINE_WORKS_PRIVATE_KEY_PATH
      LINE_WORKS_NOTIFY_USER_ID
    ]

    puts "\n環境変数チェック:"
    missing = []
    required_vars.each do |var|
      value = ENV[var]
      if value.present?
        masked = var.include?("SECRET") || var.include?("KEY") ? "***設定済み***" : value.truncate(30)
        puts "  ✅ #{var}: #{masked}"
      else
        puts "  ❌ #{var}: 未設定"
        missing << var
      end
    end

    if missing.any?
      puts "\n⚠️  未設定の環境変数があります"
      exit 1
    end

    # 秘密鍵ファイルチェック
    key_path = ENV["LINE_WORKS_PRIVATE_KEY_PATH"]
    puts "\n秘密鍵ファイルチェック:"
    if File.exist?(key_path)
      puts "  ✅ #{key_path} 存在します"
    else
      puts "  ❌ #{key_path} が見つかりません"
      exit 1
    end

    # 通知フラグ
    puts "\n通知設定:"
    enabled = ENV["LINE_WORKS_NOTIFICATIONS_ENABLED"] == "true"
    puts "  LINE_WORKS_NOTIFICATIONS_ENABLED: #{enabled ? '有効' : '無効（モック）'}"

    # 実際にトークン取得テスト
    puts "\nトークン取得テスト:"
    begin
      notifier = LineWorksNotifier.new
      if notifier.respond_to?(:test_connection)
        result = notifier.test_connection
        puts "  ✅ 接続成功"
      else
        puts "  ⚠️  test_connectionメソッドがありません（通知送信で確認してください）"
      end
    rescue => e
      puts "  ❌ エラー: #{e.message}"
    end

    puts
    puts "接続テスト完了"
  end

  private

  def test_notification(event_type, label)
    puts "#{event_type} (#{label})"
    begin
      result = yield
      if result.nil?
        puts "  ⏭️  スキップ"
        :skipped
      else
        puts "  ✅ 送信完了"
        :success
      end
    rescue => e
      puts "  ❌ エラー: #{e.message}"
      :error
    end
    puts
  end

  def infer_record_type(event_type)
    case event_type
    when /project/, /four_point/, /construction/
      "Project"
    when /budget/
      "Budget"
    when /daily_report/
      "DailyReport"
    when /invoice/
      "Invoice"
    when /payment/
      "Payment"
    when /offset/
      "Offset"
    else
      nil
    end
  end

  def find_sample_record_id(event_type, record_type)
    return nil unless record_type

    klass = record_type.constantize
    klass.last&.id
  rescue
    nil
  end
end
