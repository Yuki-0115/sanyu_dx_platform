# frozen_string_literal: true

module Importers
  class BaseImporter
    attr_reader :errors, :preview_rows

    def initialize(file, imported_by:)
      @file = file
      @imported_by = imported_by
      @errors = []
      @preview_rows = []
    end

    # Phase 1: バリデーション（DBに書き込まない）
    def validate
      @errors = []
      @preview_rows = []

      begin
        xlsx = Roo::Excelx.new(@file.respond_to?(:path) ? @file.path : @file)
      rescue StandardError => e
        @errors << "Excelファイルの読み込みに失敗しました: #{e.message}"
        return false
      end

      sheet = xlsx.sheet(0)

      if sheet.last_row.nil? || sheet.last_row < 2
        @errors << "データ行がありません（2行目以降にデータを入力してください）"
        return false
      end

      headers = sheet.row(1).map { |h| h.to_s.strip }
      validate_headers!(headers)
      return false if @errors.any?

      (2..sheet.last_row).each do |i|
        raw_row = sheet.row(i)

        # 全列空白の行はスキップ
        next if raw_row.all? { |cell| cell.nil? || cell.to_s.strip.empty? }

        row_data = parse_row(raw_row, headers)
        row_errors = validate_row(row_data, i)

        @preview_rows << {
          row_number: i,
          data: row_data,
          errors: row_errors,
          valid: row_errors.empty?
        }
      end

      if @preview_rows.empty?
        @errors << "有効なデータ行がありません"
        return false
      end

      @errors.empty?
    end

    # Phase 2: OK行のみ登録（1トランザクション）
    def import!
      raise "バリデーション未実行" if @preview_rows.empty?

      valid_rows = @preview_rows.select { |r| r[:valid] }
      error_rows = @preview_rows.reject { |r| r[:valid] }

      raise "登録可能な行がありません" if valid_rows.empty?

      import_record = ::DataImport.create!(
        import_type: import_type,
        status: "validating",
        file_name: extract_filename,
        total_rows: @preview_rows.size,
        imported_by: @imported_by
      )

      begin
        ActiveRecord::Base.transaction do
          valid_rows.each { |row| create_record!(row[:data]) }
        end

        import_record.update!(
          status: "completed",
          success_rows: valid_rows.size,
          error_rows: error_rows.size,
          error_details: error_rows.map { |r|
            { row: r[:row_number], data: r[:data], errors: r[:errors] }
          },
          skipped_rows: error_rows.map { |r|
            { row: r[:row_number], data: r[:data], errors: r[:errors] }
          }
        )
      rescue StandardError => e
        import_record.update!(
          status: "failed",
          error_details: [{ message: e.message, backtrace: e.backtrace&.first(5) }]
        )
        raise
      end

      import_record
    end

    # プレビュー集計
    def summary
      {
        total: @preview_rows.size,
        valid: @preview_rows.count { |r| r[:valid] },
        invalid: @preview_rows.count { |r| !r[:valid] }
      }
    end

    private

    # サブクラスで実装必須
    def import_type
      raise NotImplementedError
    end

    def required_headers
      raise NotImplementedError
    end

    def validate_row(_row_data, _row_number)
      raise NotImplementedError
    end

    def create_record!(_row_data)
      raise NotImplementedError
    end

    def parse_row(_raw_row, _headers)
      raise NotImplementedError
    end

    def validate_headers!(headers)
      missing = required_headers - headers
      @errors << "必須列が不足しています: #{missing.join(', ')}" if missing.any?
    end

    def extract_filename
      if @file.respond_to?(:original_filename)
        @file.original_filename
      elsif @file.respond_to?(:path)
        File.basename(@file.path)
      else
        "unknown.xlsx"
      end
    end

    # 日付パース（Excelのシリアル値対応）
    def parse_date(value)
      return nil if value.nil? || value.to_s.strip.empty?
      return value if value.is_a?(Date)
      return value.to_date if value.is_a?(DateTime) || value.is_a?(Time)

      # 文字列の場合
      Date.parse(value.to_s.strip)
    rescue ArgumentError
      nil
    end

    # 数値パース（カンマ・円マーク除去）
    def parse_number(value)
      return nil if value.nil? || value.to_s.strip.empty?
      return value if value.is_a?(Numeric)

      value.to_s.gsub(/[,¥\\s]/, "").to_f
    end

    # 整数パース
    def parse_integer(value)
      n = parse_number(value)
      n&.to_i
    end

    # ヘッダーからインデックスを安全に取得
    def header_index(headers, name)
      headers.index(name)
    end

    # 行から値を安全に取得
    def get_value(raw_row, headers, header_name)
      idx = header_index(headers, header_name)
      return nil if idx.nil?

      raw_row[idx]
    end
  end
end
