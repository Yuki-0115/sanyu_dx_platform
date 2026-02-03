# frozen_string_literal: true

module Importers
  class ProjectImporter < BaseImporter
    VALID_STATUSES = %w[draft estimating ordered preparing in_progress completed invoiced paid closed].freeze

    private

    def import_type
      "projects"
    end

    def required_headers
      %w[案件コード 案件名 顧客コード ステータス]
    end

    def validate_row(row_data, row_number)
      errors = []
      errors << "案件コードが空です" if row_data[:code].blank?
      errors << "案件名が空です" if row_data[:name].blank?

      # 顧客コード照合
      if row_data[:client_code].blank?
        errors << "顧客コードが空です"
      elsif !Client.exists?(code: row_data[:client_code])
        errors << "顧客コード「#{row_data[:client_code]}」がDBに存在しません"
      end

      # ステータスチェック
      unless VALID_STATUSES.include?(row_data[:status])
        errors << "ステータスは #{VALID_STATUSES.join('/')} のいずれかで入力してください"
      end

      # 担当者コード照合（入力されている場合のみ）
      { sales_code: "営業担当", engineering_code: "工務担当", construction_code: "工事担当" }.each do |key, label|
        if row_data[key].present? && !Employee.exists?(code: row_data[key])
          errors << "#{label}コード「#{row_data[key]}」がDBに存在しません"
        end
      end

      # 重複チェック
      if row_data[:code].present?
        errors << "案件コード「#{row_data[:code]}」は既に登録済みです" if Project.exists?(code: row_data[:code])
        dupes = @preview_rows.count { |r| r[:data][:code] == row_data[:code] && r[:valid] != false }
        errors << "案件コード「#{row_data[:code]}」がファイル内で重複しています" if dupes > 0
      end

      errors
    end

    def create_record!(row_data)
      client = Client.find_by!(code: row_data[:client_code])
      sales = row_data[:sales_code].present? ? Employee.find_by(code: row_data[:sales_code]) : nil
      engineering = row_data[:engineering_code].present? ? Employee.find_by(code: row_data[:engineering_code]) : nil
      construction = row_data[:construction_code].present? ? Employee.find_by(code: row_data[:construction_code]) : nil

      Project.create!(
        code: row_data[:code],
        name: row_data[:name],
        client_id: client.id,
        site_address: row_data[:site_address],
        status: row_data[:status],
        estimated_amount: row_data[:estimated_amount],
        order_amount: row_data[:order_amount],
        budget_amount: row_data[:budget_amount],
        sales_user_id: sales&.id,
        engineering_user_id: engineering&.id,
        construction_user_id: construction&.id
      )
    end

    def parse_row(raw_row, headers)
      {
        code: get_value(raw_row, headers, "案件コード")&.to_s&.strip,
        name: get_value(raw_row, headers, "案件名")&.to_s&.strip,
        client_code: get_value(raw_row, headers, "顧客コード")&.to_s&.strip,
        site_address: get_value(raw_row, headers, "現場住所")&.to_s&.strip,
        status: get_value(raw_row, headers, "ステータス")&.to_s&.strip,
        estimated_amount: parse_number(get_value(raw_row, headers, "見積金額")),
        order_amount: parse_number(get_value(raw_row, headers, "受注金額")),
        budget_amount: parse_number(get_value(raw_row, headers, "予算金額")),
        sales_code: get_value(raw_row, headers, "営業担当コード")&.to_s&.strip,
        engineering_code: get_value(raw_row, headers, "工務担当コード")&.to_s&.strip,
        construction_code: get_value(raw_row, headers, "工事担当コード")&.to_s&.strip
      }
    end
  end
end
