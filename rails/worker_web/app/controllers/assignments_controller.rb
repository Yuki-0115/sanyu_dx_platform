# frozen_string_literal: true

class AssignmentsController < ApplicationController
  def index
    # 作業員が過去に配置された案件一覧
    @projects = Project.joins(daily_reports: :attendances)
                       .where(attendances: { employee_id: current_worker.id })
                       .distinct
                       .order(created_at: :desc)
                       .limit(20)
  end
end
