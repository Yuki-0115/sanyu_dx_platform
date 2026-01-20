# frozen_string_literal: true

class PaymentsController < ApplicationController
  authorize_with :payments
  before_action :set_project
  before_action :set_invoice
  before_action :set_payment, only: %i[destroy]

  def new
    @payment = @invoice.payments.build(
      payment_date: Date.current
    )
  end

  def create
    @payment = @invoice.payments.build(payment_params)

    if @payment.save
      redirect_to project_invoice_path(@project, @invoice), notice: "入金を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @payment.destroy
    redirect_to project_invoice_path(@project, @invoice), notice: "入金を削除しました"
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_invoice
    @invoice = @project.invoices.find(params[:invoice_id])
  end

  def set_payment
    @payment = @invoice.payments.find(params[:id])
  end

  def payment_params
    params.require(:payment).permit(:payment_date, :amount, :payment_method, :notes)
  end
end
