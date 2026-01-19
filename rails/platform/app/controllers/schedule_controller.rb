# frozen_string_literal: true

class ScheduleController < ApplicationController
  before_action :authorize_schedule_access
  helper_method :project_active_on?

  # GET /schedule/project_assignments/:project_id
  def project_assignments
    @project = Project.find(params[:project_id])
    assignments = @project.project_assignments.includes(:employee).map do |a|
      {
        id: a.id,
        employee_id: a.employee_id,
        employee_name: a.employee.name,
        employment_type: a.employee.employment_type,
        role: a.role,
        start_date: a.start_date,
        end_date: a.end_date
      }
    end

    render json: { assignments: assignments }
  end

  def index
    # 進行中・準備中の案件を取得（人員配置情報も含む）
    @projects = Project.includes(:client, :construction_user, project_assignments: :employee)
                       .where(status: %w[ordered preparing in_progress])
                       .order(:name)

    # 全社員リスト（人員配置用）
    @employees = Employee.order(:employment_type, :name)

    # === 週表示用データ ===
    @current_week_start = if params[:week].present?
                            Date.parse(params[:week]).beginning_of_week(:sunday)
                          else
                            Date.current.beginning_of_week(:sunday)
                          end
    @week_dates = (0..6).map { |i| @current_week_start + i.days }

    # === 月表示用データ ===
    @current_month = if params[:month].present?
                       Date.parse("#{params[:month]}-01")
                     else
                       Date.current.beginning_of_month
                     end

    @start_date = @current_month.beginning_of_month.beginning_of_week(:sunday)
    @end_date = @current_month.end_of_month.end_of_week(:sunday)

    # 日付ごとの案件マッピング（その日に作業がある案件）
    @projects_by_date = {}
    (@start_date..@end_date).each do |date|
      @projects_by_date[date] = @projects.select do |project|
        project_active_on?(project, date)
      end
    end

    # カレンダー用の週配列
    @weeks = (@start_date..@end_date).to_a.each_slice(7).to_a
  end

  private

  def authorize_schedule_access
    authorize_feature!(:projects)
  end

  # 案件がその日にアクティブかどうか
  def project_active_on?(project, date)
    return false if project.scheduled_start_date.nil? && project.actual_start_date.nil?

    start_date = project.actual_start_date || project.scheduled_start_date
    end_date = project.actual_end_date || project.scheduled_end_date || (Date.current + 1.year)

    date >= start_date && date <= end_date
  end
end
