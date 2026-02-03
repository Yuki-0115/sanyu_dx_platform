# frozen_string_literal: true

module Importers
  class PartnerImporter < BaseImporter
    private

    def import_type
      "partners"
    end

    def required_headers
      %w[協力会社コード 会社名]
    end

    def validate_row(row_data, row_number)
      errors = []
      errors << "協力会社コードが空です" if row_data[:code].blank?
      errors << "会社名が空です" if row_data[:name].blank?

      if row_data[:code].present?
        errors << "協力会社コード「#{row_data[:code]}」は既に登録済みです" if Partner.exists?(code: row_data[:code])
        dupes = @preview_rows.count { |r| r[:data][:code] == row_data[:code] && r[:valid] != false }
        errors << "協力会社コード「#{row_data[:code]}」がファイル内で重複しています" if dupes > 0
      end

      if row_data[:has_temporary_employees].present? && !%w[はい いいえ].include?(row_data[:has_temporary_employees])
        errors << "仮社員ありは「はい」または「いいえ」で入力してください"
      end

      if row_data[:closing_day].present? && (row_data[:closing_day] < 1 || row_data[:closing_day] > 31)
        errors << "締日は1〜31で入力してください"
      end

      errors
    end

    def create_record!(row_data)
      Partner.create!(
        code: row_data[:code],
        name: row_data[:name],
        has_temporary_employees: row_data[:has_temporary_employees] == "はい",
        offset_rule: row_data[:offset_rule],
        closing_day: row_data[:closing_day],
        carryover_balance: row_data[:carryover_balance] || 0
      )
    end

    def parse_row(raw_row, headers)
      {
        code: get_value(raw_row, headers, "協力会社コード")&.to_s&.strip,
        name: get_value(raw_row, headers, "会社名")&.to_s&.strip,
        has_temporary_employees: get_value(raw_row, headers, "仮社員あり")&.to_s&.strip,
        offset_rule: get_value(raw_row, headers, "相殺ルール")&.to_s&.strip,
        closing_day: parse_integer(get_value(raw_row, headers, "締日")),
        carryover_balance: parse_number(get_value(raw_row, headers, "繰越残高"))
      }
    end
  end
end
