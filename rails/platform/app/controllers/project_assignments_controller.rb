# frozen_string_literal: true

class ProjectAssignmentsController < ApplicationController
  before_action :authorize_projects_access
  before_action :set_project

  def create
    @assignment = @project.project_assignments.build(assignment_params)

    if @assignment.save
      redirect_to @project, notice: "人員を配置しました"
    else
      redirect_to @project, alert: @assignment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @assignment = @project.project_assignments.find(params[:id])
    @assignment.destroy
    redirect_to @project, notice: "人員配置を解除しました"
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def authorize_projects_access
    authorize_feature!(:projects)
  end

  def assignment_params
    params.require(:project_assignment).permit(:employee_id, :role, :start_date, :end_date, :notes)
  end
end
