# frozen_string_literal: true

require "open3"
require "tempfile"

# Google Drive連携サービス（rclone直接版）
# n8nを介さず、rcloneコマンドで直接Google Driveにアップロード
class GoogleDriveRcloneService
  include Singleton

  # リモート名（rclone configで設定した名前）
  REMOTE_NAME = "gdrive"

  # ルートフォルダ（共有ドライブ内のフォルダ）
  ROOT_FOLDER = "SanyuTech_DX"

  # フォルダ構成テンプレート
  PROJECT_SUBFOLDERS = %w[
    01_見積・契約
    02_現場管理
    03_安全書類
    04_写真
    05_竣工書類
    06_請求・入金
    07_領収書
  ].freeze

  # アップロード動作オプション
  UPLOAD_MODE_SKIP = :skip           # 既存ファイルがあればスキップ
  UPLOAD_MODE_OVERWRITE = :overwrite # 既存ファイルを上書き
  UPLOAD_MODE_RENAME = :rename       # 別名で保存（_1, _2...）

  class << self
    delegate :upload_document, :upload_expense_receipt, :upload_daily_report_photo,
             :create_project_folder, :list_project_files, :enabled?, :file_exists?,
             to: :instance
  end

  def enabled?
    # rcloneがインストールされていて、gdriveリモートが設定されているか確認
    return @enabled if defined?(@enabled)

    @enabled = system("which rclone > /dev/null 2>&1") &&
               system("rclone listremotes 2>/dev/null | grep -q '^#{REMOTE_NAME}:'")
  end

  # 案件フォルダを作成
  def create_project_folder(project)
    return { success: false, error: "rclone not configured" } unless enabled?

    folder_name = project_folder_name(project)
    base_path = "#{REMOTE_NAME}:#{ROOT_FOLDER}/案件/#{folder_name}"

    # メインフォルダ作成
    run_rclone("mkdir", base_path)

    # サブフォルダ作成
    PROJECT_SUBFOLDERS.each do |subfolder|
      run_rclone("mkdir", "#{base_path}/#{subfolder}")
    end

    # プロジェクトにDrive URLを保存
    project.update_column(:drive_folder_url, "https://drive.google.com/drive/folders/#{ROOT_FOLDER}/案件/#{folder_name}")

    Rails.logger.info "[GoogleDriveRclone] Project folder created: #{folder_name}"
    { success: true, folder: folder_name }
  rescue StandardError => e
    Rails.logger.error "[GoogleDriveRclone] Error creating folder: #{e.message}"
    { success: false, error: e.message }
  end

  # ProjectDocumentをアップロード
  # @param document [ProjectDocument] アップロードするドキュメント
  # @param options [Hash] オプション（mode: :skip/:overwrite/:rename）
  def upload_document(document, options = {})
    return { success: false, error: "rclone not configured" } unless enabled?
    return { success: false, error: "No file attached" } unless document.file.attached?

    project = document.project
    folder_name = project_folder_name(project)
    subfolder = category_to_subfolder(document.category)
    remote_path = "#{REMOTE_NAME}:#{ROOT_FOLDER}/案件/#{folder_name}/#{subfolder}"

    # ファイル種別（カテゴリ名）と識別子（ドキュメント名）
    file_type = category_label(document.category)
    identifier = document.name

    upload_attachment(
      document.file,
      remote_path,
      file_type,
      identifier,
      options.merge(date: document.created_at&.to_date || Date.current)
    )
  end

  # 経費の領収書をアップロード
  # @param expense [Expense] アップロードする経費
  # @param options [Hash] オプション（mode: :skip/:overwrite/:rename）
  def upload_expense_receipt(expense, options = {})
    return { success: false, error: "rclone not configured" } unless enabled?
    return { success: false, error: "No receipt attached" } unless expense.receipt.attached?

    if expense.project
      # 案件紐付きの場合
      folder_name = project_folder_name(expense.project)
      remote_path = "#{REMOTE_NAME}:#{ROOT_FOLDER}/案件/#{folder_name}/07_領収書"
    else
      # 販管費（案件なし）の場合
      year_month = expense.expense_date&.strftime("%Y年%m月") || "未分類"
      remote_path = "#{REMOTE_NAME}:#{ROOT_FOLDER}/経費/#{year_month}"
    end

    # ファイル種別と識別子
    file_type = "領収書"
    identifier = expense.respond_to?(:category_label) ? expense.category_label : expense.category

    upload_attachment(
      expense.receipt,
      remote_path,
      file_type,
      identifier,
      options.merge(date: expense.expense_date || Date.current)
    )
  end

  # 日報の写真をアップロード
  # @param daily_report [DailyReport] 日報
  # @param photo [ActiveStorage::Attached] アップロードする写真
  # @param options [Hash] オプション（mode: :skip/:overwrite/:rename）
  def upload_daily_report_photo(daily_report, photo, options = {})
    return { success: false, error: "rclone not configured" } unless enabled?

    if daily_report.project
      folder_name = project_folder_name(daily_report.project)
      remote_path = "#{REMOTE_NAME}:#{ROOT_FOLDER}/案件/#{folder_name}/04_写真/#{daily_report.report_date}"
    else
      remote_path = "#{REMOTE_NAME}:#{ROOT_FOLDER}/日報写真/#{daily_report.report_date}"
    end

    # ファイル種別と識別子
    file_type = "現場写真"
    identifier = daily_report.foreman&.name || "作業員"

    upload_attachment(
      photo,
      remote_path,
      file_type,
      identifier,
      options.merge(date: daily_report.report_date || Date.current)
    )
  end

  # 案件フォルダ内のファイル一覧を取得
  def list_project_files(project, subfolder = nil)
    return [] unless enabled?

    folder_name = project_folder_name(project)
    remote_path = "#{REMOTE_NAME}:#{ROOT_FOLDER}/案件/#{folder_name}"
    remote_path += "/#{subfolder}" if subfolder

    list_files(remote_path)
  end

  # 指定パスのファイル一覧を取得
  def list_files(remote_path)
    stdout, _stderr, status = Open3.capture3("rclone", "lsjson", remote_path)
    return [] unless status.success?

    JSON.parse(stdout).map do |item|
      {
        name: item["Name"],
        path: item["Path"],
        size: item["Size"],
        modified: item["ModTime"],
        is_dir: item["IsDir"]
      }
    end
  rescue StandardError => e
    Rails.logger.error "[GoogleDriveRclone] Error listing files: #{e.message}"
    []
  end

  # ファイルが存在するかチェック
  def file_exists?(remote_path, filename)
    files = list_files(remote_path)
    files.any? { |f| f[:name] == filename }
  end

  # 重複しないファイル名を生成
  def unique_filename(remote_path, base_filename)
    return base_filename unless file_exists?(remote_path, base_filename)

    extension = File.extname(base_filename)
    basename = File.basename(base_filename, extension)

    # 既存ファイル一覧を取得
    existing_files = list_files(remote_path).map { |f| f[:name] }

    # _1, _2, ... と番号を増やして重複しない名前を探す
    counter = 1
    loop do
      new_filename = "#{basename}_#{counter}#{extension}"
      return new_filename unless existing_files.include?(new_filename)

      counter += 1
      break if counter > 100 # 無限ループ防止
    end

    # フォールバック: タイムスタンプを追加
    "#{basename}_#{Time.current.strftime('%H%M%S')}#{extension}"
  end

  private

  def project_folder_name(project)
    return "その他" unless project

    # ファイル名として使えない文字を除去
    name = project.name.gsub(%r{[/\\:*?"<>|]}, "_")
    "#{project.code}_#{name}"
  end

  def category_to_subfolder(category)
    case category
    when "contract"
      "01_見積・契約"
    when "site_management"
      "02_現場管理"
    when "safety"
      "03_安全書類"
    when "photo"
      "04_写真"
    when "completion"
      "05_竣工書類"
    else
      "02_現場管理"
    end
  end

  # カテゴリの日本語ラベル
  def category_label(category)
    case category
    when "contract"
      "契約書類"
    when "site_management"
      "現場管理"
    when "safety"
      "安全書類"
    when "photo"
      "写真"
    when "completion"
      "竣工書類"
    when "estimate"
      "見積書"
    when "invoice"
      "請求書"
    else
      "書類"
    end
  end

  # アップロード（重複チェック・統一ファイル名形式対応）
  # @param attachment [ActiveStorage::Attached] アップロードするファイル
  # @param remote_path [String] アップロード先パス
  # @param file_type [String] ファイル種別（見積書、領収書など）
  # @param identifier [String] 識別子（案件名、日付など）
  # @param options [Hash] オプション
  #   - mode: :skip, :overwrite, :rename（デフォルト: :rename）
  #   - date: ファイル名に使う日付（デフォルト: 今日）
  def upload_attachment(attachment, remote_path, file_type, identifier = nil, options = {})
    mode = options[:mode] || UPLOAD_MODE_RENAME
    date = options[:date] || Date.current

    # フォルダを確実に作成
    run_rclone("mkdir", remote_path)

    attachment.open do |tempfile|
      original_filename = attachment.filename.to_s
      extension = File.extname(original_filename)

      # 統一ファイル名フォーマット: YYYYMMDD_種類_識別子.拡張子
      # 例: 20260131_見積書_〇〇ビル.pdf
      if identifier.present?
        base_filename = "#{date.strftime('%Y%m%d')}_#{sanitize_filename(file_type)}_#{sanitize_filename(identifier)}#{extension}"
      else
        base_filename = "#{date.strftime('%Y%m%d')}_#{sanitize_filename(file_type)}#{extension}"
      end

      # 重複チェック
      if file_exists?(remote_path, base_filename)
        case mode
        when UPLOAD_MODE_SKIP
          Rails.logger.info "[GoogleDriveRclone] Skipped (already exists): #{base_filename}"
          return { success: true, skipped: true, filename: base_filename, message: "ファイルは既に存在します" }
        when UPLOAD_MODE_OVERWRITE
          Rails.logger.info "[GoogleDriveRclone] Overwriting: #{base_filename}"
          # そのまま進む（上書き）
        when UPLOAD_MODE_RENAME
          base_filename = unique_filename(remote_path, base_filename)
          Rails.logger.info "[GoogleDriveRclone] Renamed to: #{base_filename}"
        end
      end

      # アップロード
      result = run_rclone("copyto", tempfile.path, "#{remote_path}/#{base_filename}")

      if result[:success]
        Rails.logger.info "[GoogleDriveRclone] Uploaded: #{base_filename} -> #{remote_path}"
        result[:filename] = base_filename
      end

      result
    end
  end

  # ファイル名に使えない文字を除去
  def sanitize_filename(name)
    return "" if name.nil?

    name.to_s
        .gsub(%r{[/\\:*?"<>|]}, "_") # ファイル名禁止文字
        .gsub(/\s+/, "_")            # 空白をアンダースコアに
        .gsub(/_+/, "_")             # 連続アンダースコアを1つに
        .gsub(/^_|_$/, "")           # 先頭・末尾のアンダースコアを除去
  end

  def run_rclone(*args)
    stdout, stderr, status = Open3.capture3("rclone", *args)

    if status.success?
      { success: true, output: stdout }
    else
      Rails.logger.warn "[GoogleDriveRclone] Command failed: rclone #{args.join(' ')}\n#{stderr}"
      { success: false, error: stderr }
    end
  end
end
