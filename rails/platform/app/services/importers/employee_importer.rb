# frozen_string_literal: true

module Importers
  class EmployeeImporter < BaseImporter
    VALID_ROLES = %w[admin management accounting sales engineering construction worker].freeze
    EMPLOYMENT_TYPE_MAP = { "正社員" => "regular", "仮社員" => "temporary", "契約" => "contract", "パート" => "part_time" }.freeze

    private

    def import_type
      "employees"
    end

    def required_headers
      %w[社員コード 氏名 雇用区分 入社日 権限]
    end

    def validate_row(row_data, row_number)
      errors = []
      errors << "社員コードが空です" if row_data[:code].blank?
      errors << "氏名が空です" if row_data[:name].blank?

      # 雇用区分チェック
      unless EMPLOYMENT_TYPE_MAP.key?(row_data[:employment_type_label])
        errors << "雇用区分は「#{EMPLOYMENT_TYPE_MAP.keys.join('/')}」のいずれかで入力してください"
      end

      # 仮社員の場合 → 協力会社コード必須（クロスバリデーション）
      if row_data[:employment_type_label] == "仮社員"
        if row_data[:partner_code].blank?
          errors << "仮社員の場合、協力会社コードは必須です"
        elsif !Partner.exists?(code: row_data[:partner_code])
          errors << "協力会社コード「#{row_data[:partner_code]}」がDBに存在しません"
        end
      end

      # 入社日チェック
      if row_data[:hire_date_raw].present? && row_data[:hire_date].nil?
        errors << "入社日の形式が不正です（YYYY-MM-DD形式で入力してください）"
      elsif row_data[:hire_date].nil?
        errors << "入社日が空です"
      end

      # 権限チェック
      unless VALID_ROLES.include?(row_data[:role])
        errors << "権限は #{VALID_ROLES.join('/')} のいずれかで入力してください"
      end

      # 重複チェック
      if row_data[:code].present?
        errors << "社員コード「#{row_data[:code]}」は既に登録済みです" if Employee.exists?(code: row_data[:code])
        dupes = @preview_rows.count { |r| r[:data][:code] == row_data[:code] && r[:valid] != false }
        errors << "社員コード「#{row_data[:code]}」がファイル内で重複しています" if dupes > 0
      end

      errors
    end

    def create_record!(row_data)
      partner = row_data[:partner_code].present? ? Partner.find_by(code: row_data[:partner_code]) : nil

      Employee.create!(
        code: row_data[:code],
        name: row_data[:name],
        name_kana: row_data[:name_kana],
        email: row_data[:email],
        phone: row_data[:phone],
        employment_type: EMPLOYMENT_TYPE_MAP[row_data[:employment_type_label]],
        partner_id: partner&.id,
        hire_date: row_data[:hire_date],
        role: row_data[:role],
        password: SecureRandom.hex(8)  # 初期パスワード
      )
    end

    def parse_row(raw_row, headers)
      hire_date_raw = get_value(raw_row, headers, "入社日")
      {
        code: get_value(raw_row, headers, "社員コード")&.to_s&.strip,
        name: get_value(raw_row, headers, "氏名")&.to_s&.strip,
        name_kana: get_value(raw_row, headers, "フリガナ")&.to_s&.strip,
        email: get_value(raw_row, headers, "メール")&.to_s&.strip,
        phone: get_value(raw_row, headers, "電話番号")&.to_s&.strip,
        employment_type_label: get_value(raw_row, headers, "雇用区分")&.to_s&.strip,
        partner_code: get_value(raw_row, headers, "協力会社コード")&.to_s&.strip,
        hire_date_raw: hire_date_raw,
        hire_date: parse_date(hire_date_raw),
        role: get_value(raw_row, headers, "権限")&.to_s&.strip
      }
    end
  end
end
