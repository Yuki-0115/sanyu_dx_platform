# frozen_string_literal: true

class ScheduleController < ApplicationController
  before_action :authorize_schedule_access

  def index
    # 表示期間（デフォルトは今月を含む3ヶ月）
    @start_date = if params[:start_date].present?
                    Date.parse(params[:start_date])
                  else
                    Date.current.beginning_of_month
                  end
    @end_date = @start_date + 2.months

    # 進行中・準備中の案件を取得（人員配置情報も含む）
    @projects = Project.includes(:client, :construction_user, project_assignments: :employee)
                       .where(status: %w[ordered preparing in_progress])
                       .order(:scheduled_start_date, :name)

    # 全社員リスト（人員配置用）
    @employees = Employee.where(employment_type: %w[regular temporary external])
                         .order(:employment_type, :name)

    # 日付の配列を生成
    @dates = (@start_date..@end_date).to_a
    @weeks = @dates.group_by { |d| d.beginning_of_week(:monday) }
  end

  private

  def authorize_schedule_access
    authorize_feature!(:projects)
  end
end
