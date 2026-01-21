# frozen_string_literal: true

module Api
  module V1
    class ProjectsController < BaseController

      # GET /api/v1/projects
      def index
        @projects = Project.includes(:client, :sales_user)
                           .order(created_at: :desc)
                           .limit(params[:limit] || 100)

        @projects = @projects.where(status: params[:status]) if params[:status].present?

        render json: {
          projects: @projects.map { |p| project_json(p) },
          total: @projects.count
        }
      end

      # GET /api/v1/projects/:id
      def show
        @project = Project.find_by(id: params[:id])
        unless @project
          render json: { error: "Project not found" }, status: :not_found
          return
        end

        render json: { project: project_json(@project, detailed: true) }
      end

      # GET /api/v1/projects/summary
      # 経営向けサマリーデータ
      def summary
        projects = Project.all
        in_progress = projects.where(status: "in_progress")

        render json: {
          summary: {
            total_count: projects.count,
            in_progress_count: in_progress.count,
            total_order_amount: projects.sum(:order_amount),
            total_budget_amount: projects.sum(:budget_amount),
            by_status: Project.group(:status).count
          }
        }
      end

      # GET /api/v1/projects/:id/assignments
      def assignments
        @project = Project.find_by(id: params[:id])
        unless @project
          render json: { error: "Project not found" }, status: :not_found
          return
        end

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

      private

      def project_json(project, detailed: false)
        data = {
          id: project.id,
          code: project.code,
          name: project.name,
          status: project.status,
          client_name: project.client&.name,
          sales_user_name: project.sales_user&.name,
          estimated_amount: project.estimated_amount,
          order_amount: project.order_amount,
          budget_amount: project.budget_amount,
          four_point_completed_at: project.four_point_completed_at,
          created_at: project.created_at,
          updated_at: project.updated_at
        }

        if detailed
          data[:client] = {
            id: project.client&.id,
            code: project.client&.code,
            name: project.client&.name
          }
          data[:daily_reports_count] = project.daily_reports.count
          data[:has_budget] = project.budget.present?
        end

        data
      end
    end
  end
end
