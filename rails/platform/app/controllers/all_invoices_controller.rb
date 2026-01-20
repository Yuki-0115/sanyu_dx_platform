# frozen_string_literal: true

class AllInvoicesController < ApplicationController
  authorize_with :invoices

  def index
    @invoices = Invoice.includes(project: :client)
                       .order(created_at: :desc)
                       .limit(100)

    @unpaid_count = Invoice.where(status: %w[issued waiting]).count
    @unpaid_amount = Invoice.where(status: %w[issued waiting]).sum(:total_amount) || 0

    # 新規請求書作成用の案件リスト（全案件から選択可能に）
    @projects = Project.all.order(:code)
  end

end
