# frozen_string_literal: true

class OffsetsController < ApplicationController
  authorize_with :offsets
  before_action :set_offset, only: %i[show edit update confirm]

  def index
    @year_month = params[:year_month] || Date.current.strftime("%Y-%m")
    @offsets = Offset.includes(:partner).for_month(@year_month).order("partners.name")
    @partners = Partner.where(has_temporary_employees: true).order(:name)

    # 各協力会社の稼働データを計算
    @attendance_summaries = calculate_partner_attendance_summaries(@year_month)
  end

  def show
    load_attendance_data
  end

  def new
    @offset = Offset.new(year_month: params[:year_month] || Date.current.strftime("%Y-%m"))
    @partners = Partner.where(has_temporary_employees: true).order(:name)

    # パートナーが指定されている場合は稼働データを取得
    if params[:partner_id].present?
      @offset.partner_id = params[:partner_id]
      load_attendance_data
    end
  end

  def edit
    @partners = Partner.where(has_temporary_employees: true).order(:name)
    load_attendance_data
  end

  def create
    @offset = Offset.new(offset_params)

    if @offset.save
      redirect_to @offset, notice: "相殺データを作成しました"
    else
      @partners = Partner.where(has_temporary_employees: true).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @offset.update(offset_params)
      redirect_to @offset, notice: "相殺データを更新しました"
    else
      @partners = Partner.where(has_temporary_employees: true).order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    if @offset.status == "draft"
      @offset.confirm!(current_employee)
      redirect_to @offset, notice: "相殺データを確定しました"
    else
      redirect_to @offset, alert: "既に確定済みです"
    end
  end

  private

  def set_offset
    @offset = Offset.find(params[:id])
  end

  def offset_params
    params.require(:offset).permit(
      :partner_id, :year_month, :total_salary, :social_insurance,
      :revenue_amount
    )
  end

  # 協力会社の稼働データを読み込む
  def load_attendance_data
    return unless @offset.partner_id.present? && @offset.year_month.present?

    year_month = @offset.year_month
    start_date = Date.parse("#{year_month}-01")
    end_date = start_date.end_of_month

    # この協力会社の仮社員リスト
    @temporary_employees = Employee.where(partner_id: @offset.partner_id, employment_type: "temporary")

    # 仮社員の出面データを集計
    @employee_summaries = []
    total_full_days = 0
    total_half_days = 0
    total_man_days = 0.0
    total_salary = 0
    total_social_insurance = 0

    @temporary_employees.each do |emp|
      attendances = Attendance.joins(:daily_report)
                              .where(employee: emp)
                              .where(daily_reports: { report_date: start_date..end_date })
                              .includes(daily_report: :project)

      # 日付ごとにグループ化（重複排除）
      by_date = attendances.group_by { |att| att.daily_report.report_date }

      full_days = 0
      half_days = 0

      by_date.each do |_date, daily_atts|
        if daily_atts.any? { |a| a.attendance_type == "full" }
          full_days += 1
        elsif daily_atts.any? { |a| a.attendance_type == "half" }
          half_days += 1
        end
      end

      man_days = full_days + (half_days * 0.5)

      # 給与計算（日給ベースまたは月給ベース）
      if emp.daily_rate.to_i > 0
        # 日給計算
        emp_salary = (emp.daily_rate * man_days).to_i
      else
        # 月給（稼働があれば全額）
        emp_salary = man_days > 0 ? emp.monthly_salary.to_i : 0
      end

      # 社会保険料（稼働があれば全額）
      emp_social_insurance = man_days > 0 ? emp.social_insurance_monthly.to_i : 0

      @employee_summaries << {
        employee: emp,
        full_days: full_days,
        half_days: half_days,
        man_days: man_days,
        monthly_salary: emp.monthly_salary.to_i,
        daily_rate: emp.daily_rate.to_i,
        social_insurance_monthly: emp.social_insurance_monthly.to_i,
        calculated_salary: emp_salary,
        calculated_social_insurance: emp_social_insurance
      }

      total_full_days += full_days
      total_half_days += half_days
      total_man_days += man_days
      total_salary += emp_salary
      total_social_insurance += emp_social_insurance
    end

    @attendance_total = {
      full_days: total_full_days,
      half_days: total_half_days,
      man_days: total_man_days,
      total_salary: total_salary,
      total_social_insurance: total_social_insurance
    }
  end

  # 全協力会社の稼働データを計算（一覧用）
  def calculate_partner_attendance_summaries(year_month)
    start_date = Date.parse("#{year_month}-01")
    end_date = start_date.end_of_month

    summaries = {}

    Partner.where(has_temporary_employees: true).each do |partner|
      employees = Employee.where(partner_id: partner.id, employment_type: "temporary")

      total_man_days = 0.0

      employees.each do |emp|
        attendances = Attendance.joins(:daily_report)
                                .where(employee: emp)
                                .where(daily_reports: { report_date: start_date..end_date })

        by_date = attendances.group_by { |att| att.daily_report.report_date }

        by_date.each do |_date, daily_atts|
          if daily_atts.any? { |a| a.attendance_type == "full" }
            total_man_days += 1
          elsif daily_atts.any? { |a| a.attendance_type == "half" }
            total_man_days += 0.5
          end
        end
      end

      summaries[partner.id] = {
        employee_count: employees.count,
        man_days: total_man_days
      }
    end

    summaries
  end
end
