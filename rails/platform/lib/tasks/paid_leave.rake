# frozen_string_literal: true

namespace :paid_leave do
  desc "基準日到来者に有給を自動付与（毎日実行）"
  task auto_grant: :environment do
    Rails.logger.info "[PaidLeave] 自動付与処理を開始"
    puts "[#{Time.current}] 有給自動付与処理を開始..."

    results = PaidLeaveGrantService.bulk_grant!

    # 結果をログ出力
    if results[:granted].any?
      granted_info = results[:granted].map { |r| "#{r[:employee].name}(#{r[:days]}日)" }.join(", ")
      message = "付与完了: #{results[:granted].size}名 - #{granted_info}"
      Rails.logger.info "[PaidLeave] #{message}"
      puts message
    else
      puts "付与対象者なし"
    end

    if results[:errors].any?
      error_info = results[:errors].map { |e| "#{e[:employee].name}: #{e[:error]}" }.join(", ")
      message = "エラー: #{results[:errors].size}件 - #{error_info}"
      Rails.logger.error "[PaidLeave] #{message}"
      puts message
    end

    skipped_count = results[:skipped].size
    puts "スキップ: #{skipped_count}名" if skipped_count > 0

    Rails.logger.info "[PaidLeave] 自動付与処理を終了"
    puts "[#{Time.current}] 有給自動付与処理を終了"
  end

  desc "2年経過分の有給を失効処理（毎日実行）"
  task expire: :environment do
    Rails.logger.info "[PaidLeave] 失効処理を開始"
    puts "[#{Time.current}] 有給失効処理を開始..."

    expired_count = PaidLeaveGrantService.expire_old_grants!

    if expired_count > 0
      message = "失効処理完了: #{expired_count}件"
      Rails.logger.info "[PaidLeave] #{message}"
      puts message
    else
      puts "失効対象なし"
    end

    Rails.logger.info "[PaidLeave] 失効処理を終了"
    puts "[#{Time.current}] 有給失効処理を終了"
  end

  desc "自動付与 + 失効処理を一括実行（cronから呼び出し用）"
  task daily: :environment do
    Rake::Task["paid_leave:expire"].invoke
    Rake::Task["paid_leave:auto_grant"].invoke
  end

  desc "CSVから有給付与データを一括投入（初期移行用）"
  task :import_csv, [:filepath] => :environment do |_task, args|
    require "csv"

    filepath = args[:filepath]
    unless filepath && File.exist?(filepath)
      puts "エラー: ファイルが見つかりません - #{filepath}"
      puts "使用方法: rails paid_leave:import_csv[/path/to/file.csv]"
      puts ""
      puts "CSV形式:"
      puts "  社員コード,付与日,付与日数,残日数,備考"
      puts "  EMP001,2024-04-01,10,8,初期移行"
      exit 1
    end

    Rails.logger.info "[PaidLeave] CSVインポートを開始: #{filepath}"
    puts "[#{Time.current}] CSVインポートを開始..."
    puts "ファイル: #{filepath}"
    puts ""

    success_count = 0
    error_count = 0
    errors = []

    # BOM付きUTF-8とShift_JISの両方に対応
    csv_options = { headers: true, encoding: "BOM|UTF-8" }
    begin
      csv_data = File.read(filepath, encoding: "UTF-8")
    rescue Encoding::InvalidByteSequenceError
      csv_data = File.read(filepath, encoding: "Shift_JIS:UTF-8")
    end

    CSV.parse(csv_data, **csv_options) do |row|
      employee_code = row["社員コード"]&.strip || row[0]&.strip
      grant_date_str = row["付与日"]&.strip || row[1]&.strip
      granted_days = (row["付与日数"]&.strip || row[2]&.strip).to_f
      remaining_days = (row["残日数"]&.strip || row[3]&.strip).to_f
      notes = row["備考"]&.strip || row[4]&.strip

      # 社員を検索
      employee = Employee.find_by(code: employee_code)
      unless employee
        error_count += 1
        errors << "行#{$.}: 社員コード '#{employee_code}' が見つかりません"
        next
      end

      # 付与日をパース
      begin
        grant_date = Date.parse(grant_date_str)
      rescue ArgumentError
        error_count += 1
        errors << "行#{$.}: 付与日 '#{grant_date_str}' が不正です"
        next
      end

      # 付与日数チェック
      if granted_days <= 0
        error_count += 1
        errors << "行#{$.}: 付与日数は0より大きい必要があります"
        next
      end

      # 残日数チェック
      if remaining_days < 0 || remaining_days > granted_days
        error_count += 1
        errors << "行#{$.}: 残日数が不正です（0〜付与日数の範囲で指定）"
        next
      end

      # 重複チェック
      if employee.paid_leave_grants.exists?(grant_date: grant_date)
        error_count += 1
        errors << "行#{$.}: #{employee.name}の#{grant_date}の付与は既に存在します"
        next
      end

      # 付与データ作成
      begin
        expiry_date = grant_date + 2.years
        fiscal_year = grant_date.month >= 4 ? grant_date.year : grant_date.year - 1
        used_days = granted_days - remaining_days

        PaidLeaveGrant.create!(
          employee: employee,
          grant_date: grant_date,
          expiry_date: expiry_date,
          fiscal_year: fiscal_year,
          granted_days: granted_days,
          used_days: used_days,
          remaining_days: remaining_days,
          grant_type: "manual",
          notes: notes.presence || "CSVインポート"
        )

        success_count += 1
        puts "✓ #{employee.code} #{employee.name}: #{grant_date} に #{granted_days}日付与（残#{remaining_days}日）"
      rescue => e
        error_count += 1
        errors << "行#{$.}: #{employee.name} - #{e.message}"
      end
    end

    puts ""
    puts "=" * 50
    puts "インポート完了"
    puts "  成功: #{success_count}件"
    puts "  失敗: #{error_count}件"

    if errors.any?
      puts ""
      puts "エラー詳細:"
      errors.each { |e| puts "  - #{e}" }
    end

    Rails.logger.info "[PaidLeave] CSVインポート完了: 成功#{success_count}件, 失敗#{error_count}件"
  end

  desc "CSVテンプレートを出力"
  task export_template: :environment do
    require "csv"

    filepath = Rails.root.join("tmp", "paid_leave_import_template.csv")

    CSV.open(filepath, "wb", encoding: "UTF-8") do |csv|
      csv << ["社員コード", "付与日", "付与日数", "残日数", "備考"]
      csv << ["EMP001", "2024-04-01", "10", "8", "初期移行"]
      csv << ["EMP002", "2024-04-15", "11", "11", "初期移行"]
    end

    puts "テンプレートを出力しました: #{filepath}"
  end
end
