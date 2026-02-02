# frozen_string_literal: true

module Master
  class PaymentTermsController < ApplicationController
    authorize_with :master
    before_action :set_payment_term, only: %i[edit update destroy]

    def index
      @client_terms = PaymentTerm.where(termable_type: "Client")
                                  .includes(:termable)
                                  .order("termable_id, is_default DESC")
      @partner_terms = PaymentTerm.where(termable_type: "Partner")
                                   .includes(:termable)
                                   .order("termable_id, is_default DESC")
    end

    def new
      @payment_term = PaymentTerm.new
      @termable_type = params[:termable_type] || "Client"
      @termable_id = params[:termable_id]
    end

    def create
      @payment_term = PaymentTerm.new(payment_term_params)

      if @payment_term.save
        redirect_to master_payment_terms_path, notice: "支払サイトを登録しました"
      else
        @termable_type = @payment_term.termable_type || "Client"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @payment_term.update(payment_term_params)
        redirect_to master_payment_terms_path, notice: "支払サイトを更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @payment_term.destroy!
      redirect_to master_payment_terms_path, notice: "支払サイトを削除しました"
    end

    private

    def set_payment_term
      @payment_term = PaymentTerm.find(params[:id])
    end

    def payment_term_params
      params.require(:payment_term).permit(
        :termable_type, :termable_id, :name, :closing_day,
        :payment_month_offset, :payment_day, :is_default, :notes
      )
    end
  end
end
