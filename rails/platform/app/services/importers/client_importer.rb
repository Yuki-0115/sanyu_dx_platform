# frozen_string_literal: true

module Importers
  class ClientImporter < BaseImporter
    private

    def import_type
      "clients"
    end

    def required_headers
      %w[顧客コード 顧客名]
    end

    def validate_row(row_data, row_number)
      errors = []
      errors << "顧客コードが空です" if row_data[:code].blank?
      errors << "顧客名が空です" if row_data[:name].blank?

      if row_data[:code].present?
        errors << "顧客コード「#{row_data[:code]}」は既に登録済みです" if Client.exists?(code: row_data[:code])

        dupes = @preview_rows.count { |r| r[:data][:code] == row_data[:code] && r[:valid] != false }
        errors << "顧客コード「#{row_data[:code]}」がファイル内で重複しています" if dupes > 0
      end

      if row_data[:contact_email].present? && !row_data[:contact_email].match?(/\A[^@\s]+@[^@\s]+\z/)
        errors << "メールアドレスの形式が不正です"
      end

      errors
    end

    def create_record!(row_data)
      Client.create!(
        code: row_data[:code],
        name: row_data[:name],
        name_kana: row_data[:name_kana],
        postal_code: row_data[:postal_code],
        address: row_data[:address],
        phone: row_data[:phone],
        contact_name: row_data[:contact_name],
        contact_email: row_data[:contact_email],
        payment_terms_text: row_data[:payment_terms],
        notes: row_data[:notes]
      )
    end

    def parse_row(raw_row, headers)
      {
        code: get_value(raw_row, headers, "顧客コード")&.to_s&.strip,
        name: get_value(raw_row, headers, "顧客名")&.to_s&.strip,
        name_kana: get_value(raw_row, headers, "フリガナ")&.to_s&.strip,
        postal_code: get_value(raw_row, headers, "郵便番号")&.to_s&.strip,
        address: get_value(raw_row, headers, "住所")&.to_s&.strip,
        phone: get_value(raw_row, headers, "電話番号")&.to_s&.strip,
        contact_name: get_value(raw_row, headers, "担当者名")&.to_s&.strip,
        contact_email: get_value(raw_row, headers, "担当者メール")&.to_s&.strip,
        payment_terms: get_value(raw_row, headers, "支払条件")&.to_s&.strip,
        notes: get_value(raw_row, headers, "備考")&.to_s&.strip
      }
    end
  end
end
