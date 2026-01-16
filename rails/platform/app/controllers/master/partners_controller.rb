# frozen_string_literal: true

module Master
  class PartnersController < ApplicationController
    before_action :authorize_master_access
    before_action :set_partner, only: %i[show edit update destroy]

    def index
      @partners = Partner.order(:code)
    end

    def show
      @employees = @partner.employees.order(:code)
    end

    def new
      @partner = Partner.new
    end

    def edit; end

    def create
      @partner = Partner.new(partner_params)

      if @partner.save
        redirect_to master_partners_path, notice: "協力会社を登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @partner.update(partner_params)
        redirect_to master_partners_path, notice: "協力会社を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @partner.destroy
        redirect_to master_partners_path, notice: "協力会社を削除しました"
      else
        redirect_to master_partners_path, alert: "削除できませんでした: #{@partner.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_partner
      @partner = Partner.find(params[:id])
    end

    def authorize_master_access
      authorize_feature!(:master)
    end

    def partner_params
      params.require(:partner).permit(
        :code, :name, :has_temporary_employees, :offset_rule, :closing_day, :carryover_balance
      )
    end
  end
end
