# frozen_string_literal: true

module Importers
  class OffsetImporter < BaseImporter
    private

    def import_type
      "offsets"
    end

    def required_headers
      %w[協力会社コード 対象年月 繰越残高]
    end

    def validate_row(row_data, row_number)
      errors = []

      if row_data[:partner_code].blank?
        errors << "協力会社コードが空です"
      elsif !Partner.exists?(code: row_data[:partner_code])
        errors << "協力会社コード「#{row_data[:partner_code]}」がDBに存在しません"
      end

      if row_data[:year_month].blank? || !row_data[:year_month].match?(/\A\d{4}-\d{2}\z/)
        errors << "対象年月はYYYY-MM形式で入力してください"
      end

      if row_data[:balance].nil?
        errors << "繰越残高を入力してください"
      end

      # 同一協力会社・同一年月の重複チェック
      if row_data[:partner_code].present? && row_data[:year_month].present?
        partner = Partner.find_by(code: row_data[:partner_code])
        if partner && Offset.exists?(partner_id: partner.id, year_month: row_data[:year_month])
          errors << "協力会社「#{row_data[:partner_code]}」の年月「#{row_data[:year_month]}」は既に登録済みです"
        end

        dupes = @preview_rows.count do |r|
          r[:data][:partner_code] == row_data[:partner_code] &&
            r[:data][:year_month] == row_data[:year_month] &&
            r[:valid] != false
        end
        if dupes > 0
          errors << "協力会社「#{row_data[:partner_code]}」の年月「#{row_data[:year_month]}」がファイル内で重複しています"
        end
      end

      errors
    end

    def create_record!(row_data)
      partner = Partner.find_by!(code: row_data[:partner_code])

      Offset.create!(
        partner_id: partner.id,
        year_month: row_data[:year_month],
        total_salary: row_data[:total_salary] || 0,
        social_insurance: row_data[:social_insurance] || 0,
        offset_amount: row_data[:offset_amount] || 0,
        revenue_amount: row_data[:revenue_amount] || 0,
        balance: row_data[:balance],
        status: "confirmed"
      )
    end

    def parse_row(raw_row, headers)
      {
        partner_code: get_value(raw_row, headers, "協力会社コード")&.to_s&.strip,
        year_month: get_value(raw_row, headers, "対象年月")&.to_s&.strip,
        total_salary: parse_number(get_value(raw_row, headers, "給与総額")),
        social_insurance: parse_number(get_value(raw_row, headers, "社会保険")),
        offset_amount: parse_number(get_value(raw_row, headers, "相殺額")),
        revenue_amount: parse_number(get_value(raw_row, headers, "売上額")),
        balance: parse_number(get_value(raw_row, headers, "繰越残高")),
        notes: get_value(raw_row, headers, "備考")&.to_s&.strip
      }
    end
  end
end
