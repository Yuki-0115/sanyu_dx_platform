# frozen_string_literal: true

module Master
  class FixedExpenseSchedulesController < ApplicationController
    authorize_with :master
    before_action :set_schedule, only: %i[edit update destroy]

    def index
      @schedules = FixedExpenseSchedule.order(:category, :payment_day)
    end

    def new
      @schedule = FixedExpenseSchedule.new
    end

    def create
      @schedule = FixedExpenseSchedule.new(schedule_params)

      if @schedule.save
        redirect_to master_fixed_expense_schedules_path, notice: "固定費スケジュールを登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @schedule.update(schedule_params)
        redirect_to master_fixed_expense_schedules_path, notice: "固定費スケジュールを更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @schedule.destroy!
      redirect_to master_fixed_expense_schedules_path, notice: "固定費スケジュールを削除しました"
    end

    private

    def set_schedule
      @schedule = FixedExpenseSchedule.find(params[:id])
    end

    def schedule_params
      params.require(:fixed_expense_schedule).permit(
        :name, :category, :payment_day, :amount, :is_variable, :active, :notes
      )
    end
  end
end
