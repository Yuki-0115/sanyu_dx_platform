# frozen_string_literal: true

class DataImportsController < ApplicationController
  before_action :authenticate_employee!
  before_action :require_admin_or_management!

  # GET /data_imports — ステップ一覧
  def index
    @steps = ::DataImport::STEP_ORDER.map do |type|
      last_import = ::DataImport.where(import_type: type).order(created_at: :desc).first
      {
        type: type,
        label: ::DataImport::STEP_LABELS[type],
        available: ::DataImport.step_available?(type),
        completed: ::DataImport.step_completed?(type),
        has_data: ::DataImport.model_has_data?(type),
        last_import: last_import
      }
    end

    @recent_imports = ::DataImport.recent.includes(:imported_by).limit(10)
  end

  # GET /data_imports/:import_type/new — アップロード画面
  def new
    @import_type = params[:import_type]

    unless ::DataImport::IMPORT_TYPES.include?(@import_type)
      redirect_to data_imports_path, alert: "不正な取込種別です"
      return
    end

    unless ::DataImport.step_available?(@import_type)
      redirect_to data_imports_path, alert: "前提ステップが未完了です"
      return
    end

    @label = ::DataImport::STEP_LABELS[@import_type]
    @importer_class = resolve_importer(@import_type)
    @required_headers = @importer_class.new(nil, imported_by: nil).send(:required_headers)
  end

  # POST /data_imports/:import_type/preview — プレビュー
  def preview
    @import_type = params[:import_type]
    @label = ::DataImport::STEP_LABELS[@import_type]

    unless params[:file].present?
      redirect_to new_data_imports_path(import_type: @import_type), alert: "ファイルを選択してください"
      return
    end

    importer_class = resolve_importer(@import_type)
    @importer = importer_class.new(params[:file], imported_by: current_employee)
    @all_valid = @importer.validate
    @preview_rows = @importer.preview_rows
    @errors = @importer.errors
    @summary = @importer.summary

    # importerをセッションに保存はできないのでファイルを一時保存
    if @errors.empty?
      safe_filename = File.basename(params[:file].original_filename).gsub(/[\/\\]/, "_")
      temp_path = Rails.root.join("tmp", "imports", "#{SecureRandom.hex}_#{safe_filename}")
      FileUtils.mkdir_p(File.dirname(temp_path))
      FileUtils.cp(params[:file].tempfile.path, temp_path)
      session[:import_temp_file] = temp_path.to_s
      session[:import_type] = @import_type
    end
  end

  # POST /data_imports/:import_type/execute — 登録実行
  def execute
    @import_type = params[:import_type]

    temp_path = session.delete(:import_temp_file)
    session.delete(:import_type)

    unless temp_path && File.exist?(temp_path)
      redirect_to new_data_imports_path(import_type: @import_type), alert: "ファイルの有効期限が切れました。再度アップロードしてください"
      return
    end

    importer_class = resolve_importer(@import_type)
    file = File.open(temp_path)
    importer = importer_class.new(file, imported_by: current_employee)
    importer.validate

    begin
      @import_record = importer.import!
      FileUtils.rm_f(temp_path)

      if @import_record.has_skipped_rows?
        redirect_to result_data_import_path(@import_record),
                    notice: "#{@import_record.success_rows}件を登録しました（#{@import_record.error_rows}件はスキップ）"
      else
        redirect_to data_imports_path,
                    notice: "#{@import_record.success_rows}件を登録しました"
      end
    rescue StandardError => e
      FileUtils.rm_f(temp_path)
      redirect_to new_data_imports_path(import_type: @import_type),
                  alert: "登録に失敗しました: #{e.message}"
    end
  end

  # GET /data_imports/:id/result — 結果表示（スキップ行含む）
  def result
    @import_record = ::DataImport.find(params[:id])
  end

  # GET /data_imports/:import_type/template — テンプレートダウンロード
  def template
    @import_type = params[:import_type]

    unless ::DataImport::IMPORT_TYPES.include?(@import_type)
      redirect_to data_imports_path, alert: "不正な取込種別です"
      return
    end

    template_path = Rails.root.join("lib", "templates", "import_#{@import_type}.xlsx")

    if File.exist?(template_path)
      send_file template_path, filename: "#{@import_type}_template.xlsx"
    else
      # テンプレートファイルがない場合、CSVヘッダーを返す
      importer_class = resolve_importer(@import_type)
      headers = importer_class.new(nil, imported_by: nil).send(:required_headers)
      csv_data = headers.join(",") + "\n"

      send_data csv_data,
                filename: "#{@import_type}_template.csv",
                type: "text/csv; charset=UTF-8"
    end
  end

  private

  def resolve_importer(type)
    {
      "clients"            => ::Importers::ClientImporter,
      "partners"           => ::Importers::PartnerImporter,
      "employees"          => ::Importers::EmployeeImporter,
      "projects"           => ::Importers::ProjectImporter,
      "paid_leaves"        => ::Importers::PaidLeaveImporter,
      "offsets"            => ::Importers::OffsetImporter,
      "invoices"           => ::Importers::InvoiceImporter,
      "cash_flow_entries"  => ::Importers::CashFlowEntryImporter
    }.fetch(type) { raise ArgumentError, "不明なimport_type: #{type}" }
  end

  def require_admin_or_management!
    unless current_employee&.role.in?(%w[admin management])
      redirect_to root_path, alert: "権限がありません"
    end
  end
end
