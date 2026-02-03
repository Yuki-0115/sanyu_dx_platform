# frozen_string_literal: true

module Importers
  class PaidLeaveImporter < BaseImporter
    private

    def import_type
      "paid_leaves"
    end

    def required_headers
      %w[社員コード 付与日 付与日数 残日数]
    end

    def validate_row(row_data, row_number)
      errors = []

      # 社員コード照合
      if row_data[:employee_code].blank?
        errors << "社員コードが空です"
      elsif !Employee.exists?(code: row_data[:employee_code])
        errors << "社員コード「#{row_data[:employee_code]}」がDBに存在しません"
      end

      # 付与日チェック
      if row_data[:grant_date].nil?
        errors << "付与日が空または形式不正です（YYYY-MM-DD）"
      end

      # 付与日数チェック
      if row_data[:granted_days].nil? || row_data[:granted_days] <= 0
        errors << "付与日数は1以上の数値で入力してください"
      end

      # 残日数チェック
      if row_data[:remaining_days].nil? || row_data[:remaining_days] < 0
        errors << "残日数は0以上の数値で入力してください"
      end

      # 残日数 ≤ 付与日数（ビジネスルール）
      if row_data[:granted_days].present? && row_data[:remaining_days].present?
        if row_data[:remaining_days] > row_data[:granted_days]
          errors << "残日数（#{row_data[:remaining_days]}）が付与日数（#{row_data[:granted_days]}）を超えています"
        end
      end

      # 同一社員・同一付与日の重複チェック
      if row_data[:employee_code].present? && row_data[:grant_date].present?
        employee = Employee.find_by(code: row_data[:employee_code])
        if employee && PaidLeaveGrant.exists?(employee_id: employee.id, grant_date: row_data[:grant_date])
          errors << "社員「#{row_data[:employee_code]}」の付与日「#{row_data[:grant_date]}」は既に登録済みです"
        end

        # ファイル内重複
        dupes = @preview_rows.count do |r|
          r[:data][:employee_code] == row_data[:employee_code] &&
            r[:data][:grant_date] == row_data[:grant_date] &&
            r[:valid] != false
        end
        if dupes > 0
          errors << "社員「#{row_data[:employee_code]}」の付与日「#{row_data[:grant_date]}」がファイル内で重複しています"
        end
      end

      errors
    end

    def create_record!(row_data)
      employee = Employee.find_by!(code: row_data[:employee_code])
      grant_date = row_data[:grant_date]
      expiry_date = grant_date + 2.years  # 有給は付与日から2年で失効
      fiscal_year = grant_date.month >= 4 ? grant_date.year : grant_date.year - 1

      PaidLeaveGrant.create!(
        employee_id: employee.id,
        grant_date: grant_date,
        expiry_date: expiry_date,
        fiscal_year: fiscal_year,
        granted_days: row_data[:granted_days],
        used_days: row_data[:granted_days] - row_data[:remaining_days],
        remaining_days: row_data[:remaining_days],
        grant_type: "manual",
        notes: row_data[:notes]
      )
    end

    def parse_row(raw_row, headers)
      {
        employee_code: get_value(raw_row, headers, "社員コード")&.to_s&.strip,
        grant_date: parse_date(get_value(raw_row, headers, "付与日")),
        granted_days: parse_number(get_value(raw_row, headers, "付与日数")),
        remaining_days: parse_number(get_value(raw_row, headers, "残日数")),
        notes: get_value(raw_row, headers, "備考")&.to_s&.strip
      }
    end
  end
end
