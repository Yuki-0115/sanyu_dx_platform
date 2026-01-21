# frozen_string_literal: true

module Master
  class EmployeesController < ApplicationController
    before_action :authorize_master_access
    before_action :set_employee, only: %i[show edit update destroy]

    EMPLOYMENT_TYPES = %w[regular temporary external].freeze
    ROLES = %w[admin management accounting sales engineering construction worker].freeze

    def index
      @employees = Employee.includes(:partner).order(:code)

      if params[:employment_type].present?
        @employees = @employees.where(employment_type: params[:employment_type])
      end
    end

    def show; end

    def new
      @employee = Employee.new
    end

    def edit; end

    def create
      @employee = Employee.new(employee_params)
      @employee.password = SecureRandom.hex(8) if @employee.email.present? && @employee.password.blank?

      if @employee.save
        redirect_to master_employees_path, notice: "社員を登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      update_params = employee_params
      update_params = update_params.except(:password) if update_params[:password].blank?

      if @employee.update(update_params)
        redirect_to master_employees_path, notice: "社員を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @employee == current_employee
        redirect_to master_employees_path, alert: "自分自身は削除できません"
      elsif @employee.destroy
        redirect_to master_employees_path, notice: "社員を削除しました"
      else
        redirect_to master_employees_path, alert: "削除できませんでした: #{@employee.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_employee
      @employee = Employee.find(params[:id])
    end

    def authorize_master_access
      authorize_feature!(:master)
    end

    def employee_params
      params.require(:employee).permit(
        :code, :name, :name_kana, :email, :phone, :password,
        :employment_type, :hire_date, :role, :partner_id,
        :monthly_salary, :social_insurance_monthly, :daily_rate
      )
    end
  end
end
