# frozen_string_literal: true

module Api
  module V1
    class DailyReportsController < BaseController
      before_action :set_tenant_from_code

      # GET /api/v1/daily_reports
      def index
        @reports = DailyReport.includes(:project, :foreman, :attendances)
                              .order(report_date: :desc)
                              .limit(params[:limit] || 100)

        @reports = @reports.where(status: params[:status]) if params[:status].present?
        @reports = @reports.where("report_date >= ?", params[:from_date]) if params[:from_date].present?
        @reports = @reports.where("report_date <= ?", params[:to_date]) if params[:to_date].present?

        render json: {
          daily_reports: @reports.map { |r| report_json(r) },
          total: @reports.count
        }
      end

      # GET /api/v1/daily_reports/:id
      def show
        @report = DailyReport.find_by(id: params[:id])
        unless @report
          render json: { error: "DailyReport not found" }, status: :not_found
          return
        end

        render json: { daily_report: report_json(@report, detailed: true) }
      end

      # GET /api/v1/daily_reports/unconfirmed
      # 未確認の日報一覧（n8nでの自動リマインダー用）
      def unconfirmed
        @reports = DailyReport.includes(:project, :foreman)
                              .where(status: "draft")
                              .where("report_date < ?", Date.current)
                              .order(report_date: :asc)

        render json: {
          unconfirmed_reports: @reports.map { |r| report_json(r) },
          total: @reports.count,
          message: "#{@reports.count}件の未確認日報があります"
        }
      end

      private

      def report_json(report, detailed: false)
        data = {
          id: report.id,
          project_id: report.project_id,
          project_name: report.project&.name,
          report_date: report.report_date,
          weather: report.weather,
          status: report.status,
          foreman_name: report.foreman&.name,
          attendance_count: report.attendances.count,
          confirmed_at: report.confirmed_at,
          created_at: report.created_at
        }

        if detailed
          data[:work_content] = report.work_content
          data[:notes] = report.notes
          data[:materials_used] = report.materials_used
          data[:machines_used] = report.machines_used
          data[:labor_details] = report.labor_details
          data[:outsourcing_details] = report.outsourcing_details
          data[:labor_cost] = report.labor_cost
          data[:material_cost] = report.material_cost
          data[:outsourcing_cost] = report.outsourcing_cost
          data[:transportation_cost] = report.transportation_cost
          data[:total_cost] = report.total_cost
          data[:attendances] = report.attendances.map do |a|
            {
              id: a.id,
              employee_name: a.employee&.name || a.partner_worker_name,
              attendance_type: a.attendance_type,
              hours_worked: a.hours_worked
            }
          end
        end

        data
      end
    end
  end
end
