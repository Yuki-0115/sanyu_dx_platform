# frozen_string_literal: true

class ProjectAssignmentsController < ApplicationController
  authorize_with :projects
  before_action :set_project

  def create
    @assignment = @project.project_assignments.build(assignment_params)

    respond_to do |format|
      if @assignment.save
        format.html { redirect_to @project, notice: "人員を配置しました" }
        format.json { render json: { success: true, assignment: assignment_json(@assignment) } }
      else
        format.html { redirect_to @project, alert: @assignment.errors.full_messages.join(", ") }
        format.json { render json: { success: false, error: @assignment.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @assignment = @project.project_assignments.find(params[:id])
    @assignment.destroy

    respond_to do |format|
      format.html { redirect_to @project, notice: "人員配置を解除しました" }
      format.json { render json: { success: true } }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def assignment_params
    params.require(:project_assignment).permit(:employee_id, :role, :start_date, :end_date, :notes)
  end

  def assignment_json(assignment)
    {
      id: assignment.id,
      employee_id: assignment.employee_id,
      employee_name: assignment.employee.name,
      employment_type: assignment.employee.employment_type,
      role: assignment.role
    }
  end
end
