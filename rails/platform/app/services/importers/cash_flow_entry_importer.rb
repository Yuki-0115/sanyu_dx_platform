# frozen_string_literal: true

module Importers
  class CashFlowEntryImporter < BaseImporter
    VALID_ENTRY_TYPES = %w[income expense].freeze
    INCOME_CATEGORIES = %w[receivable other_income].freeze
    EXPENSE_CATEGORIES = %w[
      outsourcing salary social_insurance tax rent lease insurance
      vehicle phone utility card fees machine_rental advisory_fee
      materials trainee loan expense miscellaneous
    ].freeze
    VALID_STATUSES = %w[expected confirmed completed].freeze

    private

    def import_type
      "cash_flow_entries"
    end

    def required_headers
      %w[日付 入出金区分 カテゴリ 金額 ステータス]
    end

    def validate_row(row_data, row_number)
      errors = []

      # 日付チェック
      if row_data[:expected_date].nil?
        errors << "日付が空または形式不正です（YYYY-MM-DD）"
      end

      # 入出金区分チェック
      unless VALID_ENTRY_TYPES.include?(row_data[:entry_type])
        errors << "入出金区分は income（入金）/ expense（出金）で入力してください"
      end

      # カテゴリチェック
      all_categories = INCOME_CATEGORIES + EXPENSE_CATEGORIES
      if row_data[:category].present? && !all_categories.include?(row_data[:category])
        errors << "カテゴリが不正です"
      end

      # 入出金区分とカテゴリの整合性チェック
      if row_data[:entry_type] == "income" && !INCOME_CATEGORIES.include?(row_data[:category])
        errors << "入金の場合、カテゴリは receivable/other_income のいずれかで入力してください"
      end

      if row_data[:entry_type] == "expense" && !EXPENSE_CATEGORIES.include?(row_data[:category])
        errors << "出金の場合、カテゴリは #{EXPENSE_CATEGORIES.first(5).join('/')} などで入力してください"
      end

      # 金額チェック
      if row_data[:amount].nil? || row_data[:amount] <= 0
        errors << "金額は正の数値で入力してください"
      end

      # ステータスチェック
      unless VALID_STATUSES.include?(row_data[:status])
        errors << "ステータスは expected（予定）/ confirmed（確認済）/ completed（完了）で入力してください"
      end

      # 案件コード照合（入力されている場合のみ）
      if row_data[:project_code].present? && !Project.exists?(code: row_data[:project_code])
        errors << "案件コード「#{row_data[:project_code]}」がDBに存在しません"
      end

      # 協力会社コード照合（入力されている場合のみ）
      if row_data[:partner_code].present? && !Partner.exists?(code: row_data[:partner_code])
        errors << "協力会社コード「#{row_data[:partner_code]}」がDBに存在しません"
      end

      # 顧客コード照合（入力されている場合のみ）
      if row_data[:client_code].present? && !Client.exists?(code: row_data[:client_code])
        errors << "顧客コード「#{row_data[:client_code]}」がDBに存在しません"
      end

      errors
    end

    def create_record!(row_data)
      project = row_data[:project_code].present? ? Project.find_by(code: row_data[:project_code]) : nil
      partner = row_data[:partner_code].present? ? Partner.find_by(code: row_data[:partner_code]) : nil
      client = row_data[:client_code].present? ? Client.find_by(code: row_data[:client_code]) : nil

      CashFlowEntry.create!(
        entry_type: row_data[:entry_type],
        category: row_data[:category],
        base_date: row_data[:expected_date],
        expected_date: row_data[:expected_date],
        expected_amount: row_data[:amount],
        status: row_data[:status],
        project_id: project&.id,
        partner_id: partner&.id,
        client_id: client&.id,
        notes: row_data[:notes]
      )
    end

    def parse_row(raw_row, headers)
      {
        expected_date: parse_date(get_value(raw_row, headers, "日付")),
        entry_type: get_value(raw_row, headers, "入出金区分")&.to_s&.strip,
        category: get_value(raw_row, headers, "カテゴリ")&.to_s&.strip,
        amount: parse_number(get_value(raw_row, headers, "金額")),
        status: get_value(raw_row, headers, "ステータス")&.to_s&.strip,
        project_code: get_value(raw_row, headers, "案件コード")&.to_s&.strip,
        partner_code: get_value(raw_row, headers, "協力会社コード")&.to_s&.strip,
        client_code: get_value(raw_row, headers, "顧客コード")&.to_s&.strip,
        notes: get_value(raw_row, headers, "備考")&.to_s&.strip
      }
    end
  end
end
