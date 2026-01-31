# frozen_string_literal: true

namespace :google_drive do
  desc "Google Drive連携の状態確認"
  task status: :environment do
    puts "=" * 50
    puts "Google Drive連携ステータス"
    puts "=" * 50
    puts

    # rclone版
    if GoogleDriveRcloneService.enabled?
      puts "✅ rclone版: 有効"
      puts "   リモート: gdrive (共有ドライブ)"
    else
      puts "❌ rclone版: 無効"
      puts "   → make backup-gdrive で設定してください"
    end

    puts

    # n8n版
    if GoogleDriveService.enabled?
      puts "✅ n8n版: 有効"
    else
      puts "⚠️  n8n版: 無効"
    end

    puts
    puts "=" * 50
  end

  desc "Google Driveにルートフォルダ構造を作成"
  task setup: :environment do
    unless GoogleDriveRcloneService.enabled?
      puts "❌ rcloneが設定されていません"
      puts "   make backup-gdrive を実行してください"
      exit 1
    end

    puts "Google Driveフォルダ構造を作成中..."
    puts

    root = "gdrive:SanyuTech_DX"
    folders = [
      "案件",
      "経費",
      "月次帳票",
      "安全書類",
      "日報写真"
    ]

    # ルートフォルダ作成
    system("rclone mkdir #{root}")
    puts "✅ #{root}"

    # サブフォルダ作成
    folders.each do |folder|
      system("rclone mkdir #{root}/#{folder}")
      puts "✅ #{root}/#{folder}"
    end

    puts
    puts "フォルダ構造の作成が完了しました"
  end

  desc "既存の全案件のフォルダを作成"
  task create_all_project_folders: :environment do
    unless GoogleDriveRcloneService.enabled?
      puts "❌ rcloneが設定されていません"
      exit 1
    end

    projects = Project.all
    puts "#{projects.count}件の案件フォルダを作成します..."
    puts

    projects.each_with_index do |project, index|
      print "[#{index + 1}/#{projects.count}] #{project.code} #{project.name}..."
      result = GoogleDriveRcloneService.create_project_folder(project)
      if result[:success]
        puts " ✅"
      else
        puts " ❌ #{result[:error]}"
      end
    end

    puts
    puts "完了"
  end

  desc "未同期のドキュメントをGoogle Driveにアップロード"
  task sync_documents: :environment do
    unless GoogleDriveRcloneService.enabled?
      puts "❌ rcloneが設定されていません"
      exit 1
    end

    documents = ProjectDocument.includes(:project).where.not(project_id: nil)
    puts "#{documents.count}件のドキュメントを同期します..."
    puts

    success_count = 0
    error_count = 0

    documents.find_each do |doc|
      next unless doc.file.attached?

      print "#{doc.project.code}/#{doc.name}..."
      result = GoogleDriveRcloneService.upload_document(doc)
      if result[:success]
        puts " ✅"
        success_count += 1
      else
        puts " ❌ #{result[:error]}"
        error_count += 1
      end
    end

    puts
    puts "完了: 成功 #{success_count}件, 失敗 #{error_count}件"
  end

  desc "未同期の領収書をGoogle Driveにアップロード"
  task sync_receipts: :environment do
    unless GoogleDriveRcloneService.enabled?
      puts "❌ rcloneが設定されていません"
      exit 1
    end

    expenses = Expense.joins(:receipt_attachment).where.not(receipt_attachment: nil)
    puts "#{expenses.count}件の領収書を同期します..."
    puts

    success_count = 0
    error_count = 0

    expenses.find_each do |expense|
      next unless expense.receipt.attached?

      project_info = expense.project ? expense.project.code : "販管費"
      print "#{project_info}/#{expense.expense_date}/#{expense.category}..."
      result = GoogleDriveRcloneService.upload_expense_receipt(expense)
      if result[:success]
        puts " ✅"
        success_count += 1
      else
        puts " ❌ #{result[:error]}"
        error_count += 1
      end
    end

    puts
    puts "完了: 成功 #{success_count}件, 失敗 #{error_count}件"
  end

  desc "Google Driveのフォルダ一覧を表示"
  task list: :environment do
    path = ENV["path"] || "SanyuTech_DX"

    unless GoogleDriveRcloneService.enabled?
      puts "❌ rcloneが設定されていません"
      exit 1
    end

    puts "gdrive:#{path} の内容:"
    puts
    system("rclone lsd gdrive:#{path}")
  end

  desc "テストファイルをアップロード"
  task test_upload: :environment do
    unless GoogleDriveRcloneService.enabled?
      puts "❌ rcloneが設定されていません"
      exit 1
    end

    require "tempfile"

    puts "テストファイルをアップロード中..."

    Tempfile.create(["test", ".txt"]) do |f|
      f.write("SanyuTech DX Platform テストファイル\n")
      f.write("作成日時: #{Time.current}\n")
      f.flush

      result = system("rclone copyto #{f.path} gdrive:SanyuTech_DX/test_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt")

      if result
        puts "✅ テストアップロード成功"
        puts
        puts "Google Driveを確認してください:"
        system("rclone ls gdrive:SanyuTech_DX/ | grep test_")
      else
        puts "❌ テストアップロード失敗"
      end
    end
  end
end
