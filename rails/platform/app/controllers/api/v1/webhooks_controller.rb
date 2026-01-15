# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < BaseController
      before_action :set_tenant_from_code

      # POST /api/v1/webhooks/project_created
      # n8nから呼ばれ、LINE WORKS通知をトリガー
      def project_created
        project = Project.find_by(id: params[:project_id])
        unless project
          render json: { error: "Project not found" }, status: :not_found
          return
        end

        notification_data = {
          type: "project_created",
          project: {
            id: project.id,
            code: project.code,
            name: project.name,
            client_name: project.client&.name,
            status: project.status
          },
          message: "新規案件が登録されました: #{project.name}"
        }

        # LINE WORKS通知用のレスポンス
        render json: { success: true, notification: notification_data }
      end

      # POST /api/v1/webhooks/four_point_completed
      # 4点チェック完了時の通知
      def four_point_completed
        project = Project.find_by(id: params[:project_id])
        unless project
          render json: { error: "Project not found" }, status: :not_found
          return
        end

        notification_data = {
          type: "four_point_completed",
          project: {
            id: project.id,
            code: project.code,
            name: project.name,
            order_amount: project.order_amount,
            four_point_approved_at: project.four_point_approved_at
          },
          message: "4点チェックが完了しました: #{project.name}"
        }

        render json: { success: true, notification: notification_data }
      end

      # POST /api/v1/webhooks/budget_confirmed
      # 実行予算確定時の通知
      def budget_confirmed
        budget = Budget.find_by(id: params[:budget_id])
        unless budget
          render json: { error: "Budget not found" }, status: :not_found
          return
        end

        notification_data = {
          type: "budget_confirmed",
          budget: {
            id: budget.id,
            project_name: budget.project&.name,
            total_cost: budget.total_cost,
            confirmed_at: budget.confirmed_at
          },
          message: "実行予算が確定しました: #{budget.project&.name}"
        }

        render json: { success: true, notification: notification_data }
      end

      # POST /api/v1/webhooks/daily_report_submitted
      # 日報提出時の通知
      def daily_report_submitted
        report = DailyReport.find_by(id: params[:daily_report_id])
        unless report
          render json: { error: "DailyReport not found" }, status: :not_found
          return
        end

        notification_data = {
          type: "daily_report_submitted",
          daily_report: {
            id: report.id,
            project_name: report.project&.name,
            report_date: report.report_date,
            weather: report.weather,
            attendance_count: report.attendances.count
          },
          message: "日報が提出されました: #{report.project&.name} (#{report.report_date})"
        }

        render json: { success: true, notification: notification_data }
      end

      # POST /api/v1/webhooks/offset_confirmed
      # 相殺確定時の通知
      def offset_confirmed
        offset = Offset.find_by(id: params[:offset_id])
        unless offset
          render json: { error: "Offset not found" }, status: :not_found
          return
        end

        notification_data = {
          type: "offset_confirmed",
          offset: {
            id: offset.id,
            partner_name: offset.partner&.name,
            year_month: offset.year_month,
            offset_amount: offset.offset_amount,
            balance: offset.balance
          },
          message: "相殺が確定しました: #{offset.partner&.name} (#{offset.year_month})"
        }

        render json: { success: true, notification: notification_data }
      end
    end
  end
end
