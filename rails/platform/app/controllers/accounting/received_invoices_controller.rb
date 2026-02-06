# frozen_string_literal: true

module Accounting
  class ReceivedInvoicesController < ApplicationController
    before_action :set_invoice, only: %i[approve reject destroy]

    def index
      @pending_invoices = ReceivedInvoice.pending.includes(:uploaded_by, :partner, :client,
        :accounting_approved_by, :sales_approved_by, :engineering_approved_by).recent
      @approved_invoices = ReceivedInvoice.approved.includes(:uploaded_by, :partner, :client,
        :accounting_approved_by, :sales_approved_by, :engineering_approved_by).recent.limit(20)
      @rejected_invoices = ReceivedInvoice.rejected.includes(:uploaded_by, :approved_by, :partner, :client).recent.limit(10)
    end

    def new
      @invoice = ReceivedInvoice.new
      @partners = Partner.order(:name)
      @clients = Client.order(:name)
    end

    def create
      @invoice = ReceivedInvoice.new(invoice_params)
      @invoice.uploaded_by = current_employee
      @invoice.status = "pending"

      if @invoice.save
        redirect_to accounting_received_invoices_path, notice: "請求書を登録しました"
      else
        @partners = Partner.order(:name)
        @clients = Client.order(:name)
        render :new, status: :unprocessable_entity
      end
    end

    def approve
      approval_type = params[:approval_type]

      unless ReceivedInvoice::APPROVAL_TYPES.include?(approval_type)
        redirect_to accounting_received_invoices_path, alert: "不正な承認タイプです"
        return
      end

      if @invoice.approve!(current_employee, approval_type)
        label = ReceivedInvoice::APPROVAL_LABELS[approval_type]
        redirect_to accounting_received_invoices_path, notice: "#{label}確認しました"
      else
        redirect_to accounting_received_invoices_path, alert: "確認に失敗しました"
      end
    end

    def reject
      reason = params[:rejection_reason]

      if reason.blank?
        redirect_to accounting_received_invoices_path, alert: "却下理由を入力してください"
        return
      end

      if @invoice.reject!(current_employee, reason)
        redirect_to accounting_received_invoices_path, notice: "却下しました"
      else
        redirect_to accounting_received_invoices_path, alert: "却下に失敗しました"
      end
    end

    def destroy
      @invoice.destroy
      redirect_to accounting_received_invoices_path, notice: "請求書を削除しました"
    end

    private

    def set_invoice
      @invoice = ReceivedInvoice.find(params[:id])
    end

    def invoice_params
      params.require(:received_invoice).permit(:partner_id, :client_id, :vendor_name, :description, attachments: [])
    end
  end
end
