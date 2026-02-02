# frozen_string_literal: true

module Master
  class FixedExpenseMonthlyAmountsController < ApplicationController
    authorize_with :master
    before_action :set_schedule

    def index
      @monthly_amounts = @schedule.monthly_amounts.order(year: :desc, month: :desc)
      @new_amount = @schedule.monthly_amounts.build
    end

    def create
      @amount = @schedule.monthly_amounts.build(amount_params)

      if @amount.save
        redirect_to master_fixed_expense_schedule_monthly_amounts_path(@schedule),
                    notice: "#{@amount.month_label}の金額を登録しました"
      else
        @monthly_amounts = @schedule.monthly_amounts.order(year: :desc, month: :desc)
        @new_amount = @amount
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @amount = @schedule.monthly_amounts.find(params[:id])
      label = @amount.month_label
      @amount.destroy!
      redirect_to master_fixed_expense_schedule_monthly_amounts_path(@schedule),
                  notice: "#{label}の金額を削除しました"
    end

    private

    def set_schedule
      @schedule = FixedExpenseSchedule.find(params[:fixed_expense_schedule_id])
    end

    def amount_params
      params.require(:fixed_expense_monthly_amount).permit(:year, :month, :amount, :notes)
    end
  end
end
