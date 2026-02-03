# frozen_string_literal: true

module Importers
  class InvoiceImporter < BaseImporter
    VALID_STATUSES = %w[draft issued waiting paid overdue].freeze

    private

    def import_type
      "invoices"
    end

    def required_headers
      %w[案件コード 請求金額 ステータス]
    end

    def validate_row(row_data, row_number)
      errors = []

      if row_data[:project_code].blank?
        errors << "案件コードが空です"
      elsif !Project.exists?(code: row_data[:project_code])
        errors << "案件コード「#{row_data[:project_code]}」がDBに存在しません"
      end

      if row_data[:amount].nil? || row_data[:amount] <= 0
        errors << "請求金額は正の数値で入力してください"
      end

      unless VALID_STATUSES.include?(row_data[:status])
        errors << "ステータスは #{VALID_STATUSES.join('/')} のいずれかで入力してください"
      end

      # 合計チェック（手入力がある場合）
      if row_data[:amount].present? && row_data[:tax_amount].present? && row_data[:total_amount].present?
        expected = row_data[:amount] + row_data[:tax_amount]
        if (row_data[:total_amount] - expected).abs > 1  # 1円の誤差は許容
          errors << "合計（#{row_data[:total_amount].to_i}）が請求金額+消費税（#{expected.to_i}）と一致しません"
        end
      end

      errors
    end

    def create_record!(row_data)
      project = Project.find_by!(code: row_data[:project_code])

      # 消費税・合計を自動計算（手入力がない場合）
      tax = row_data[:tax_amount] || (row_data[:amount] * 0.1).round
      total = row_data[:total_amount] || (row_data[:amount] + tax)

      Invoice.create!(
        project_id: project.id,
        invoice_number: row_data[:invoice_number],
        amount: row_data[:amount],
        tax_amount: tax,
        total_amount: total,
        issued_date: row_data[:issued_date],
        due_date: row_data[:due_date],
        status: row_data[:status]
      )
    end

    def parse_row(raw_row, headers)
      {
        project_code: get_value(raw_row, headers, "案件コード")&.to_s&.strip,
        invoice_number: get_value(raw_row, headers, "請求書番号")&.to_s&.strip,
        amount: parse_number(get_value(raw_row, headers, "請求金額")),
        tax_amount: parse_number(get_value(raw_row, headers, "消費税")),
        total_amount: parse_number(get_value(raw_row, headers, "合計")),
        issued_date: parse_date(get_value(raw_row, headers, "発行日")),
        due_date: parse_date(get_value(raw_row, headers, "支払期日")),
        status: get_value(raw_row, headers, "ステータス")&.to_s&.strip
      }
    end
  end
end
