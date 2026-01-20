# frozen_string_literal: true

class InvoicesController < ApplicationController
  authorize_with :invoices
  before_action :set_project
  before_action :set_invoice, only: %i[show edit update destroy issue]

  def index
    @invoices = @project.invoices.order(created_at: :desc)
  end

  def show; end

  def new
    @invoice = @project.invoices.build(
      issued_date: Date.current,
      due_date: Date.current + 30.days
    )
  end

  def edit; end

  def create
    @invoice = @project.invoices.build(invoice_params)

    if @invoice.save
      redirect_to project_invoice_path(@project, @invoice), notice: "請求書を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @invoice.update(invoice_params)
      redirect_to project_invoice_path(@project, @invoice), notice: "請求書を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @invoice.payments.any?
      redirect_to project_invoice_path(@project, @invoice), alert: "入金があるため削除できません"
    elsif @invoice.destroy
      redirect_to project_invoices_path(@project), notice: "請求書を削除しました"
    else
      redirect_to project_invoice_path(@project, @invoice), alert: "削除に失敗しました"
    end
  end

  def issue
    if @invoice.status == "draft"
      @invoice.issue!
      redirect_to project_invoice_path(@project, @invoice), notice: "請求書を発行しました"
    else
      redirect_to project_invoice_path(@project, @invoice), alert: "この請求書は既に発行済みです"
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_invoice
    @invoice = @project.invoices.find(params[:id])
  end

  def invoice_params
    params.require(:invoice).permit(
      :invoice_number, :issued_date, :due_date, :amount, :tax_amount, :total_amount, :description,
      invoice_items_attributes: %i[id name work_date quantity unit unit_price subtotal description position _destroy]
    )
  end
end
