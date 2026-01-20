# frozen_string_literal: true

module Master
  class CompanyEventsController < ApplicationController
    before_action :authorize_view_access!
    before_action :authorize_edit_access!, except: [:index]
    before_action :set_company_event, only: [:update, :destroy]

    def index
      @year = params[:year]&.to_i || Date.current.year
      @calendar_type = params[:calendar_type] || "all"

      @events = CompanyEvent
        .for_year(@year)
        .for_calendar_type(@calendar_type)
        .order(:event_date, :name)

      respond_to do |format|
        format.html
        format.json { render json: @events }
      end
    end

    def create
      @company_event = CompanyEvent.new(company_event_params)

      if @company_event.save
        respond_to do |format|
          format.html { redirect_to master_company_holidays_path(year: @company_event.event_date.year, calendar_type: params[:current_calendar_type] || "worker"), notice: "行事を追加しました" }
          format.json { render json: { success: true, event: event_json(@company_event) } }
        end
      else
        respond_to do |format|
          format.html { redirect_to master_company_holidays_path, alert: @company_event.errors.full_messages.join(", ") }
          format.json { render json: { success: false, errors: @company_event.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def update
      if @company_event.update(company_event_params)
        respond_to do |format|
          format.html { redirect_to master_company_holidays_path(year: @company_event.event_date.year, calendar_type: params[:current_calendar_type] || "worker"), notice: "行事を更新しました" }
          format.json { render json: { success: true, event: event_json(@company_event) } }
        end
      else
        respond_to do |format|
          format.html { redirect_to master_company_holidays_path, alert: @company_event.errors.full_messages.join(", ") }
          format.json { render json: { success: false, errors: @company_event.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      year = @company_event.event_date.year
      @company_event.destroy

      respond_to do |format|
        format.html { redirect_to master_company_holidays_path(year: year, calendar_type: params[:current_calendar_type] || "worker"), notice: "行事を削除しました" }
        format.json { render json: { success: true } }
      end
    end

    private

    def set_company_event
      @company_event = CompanyEvent.find(params[:id])
    end

    def company_event_params
      params.require(:company_event).permit(:event_date, :name, :description, :calendar_type, :color)
    end

    def authorize_view_access!
      unless current_employee
        redirect_to root_path, alert: "ログインが必要です"
      end
    end

    def authorize_edit_access!
      unless can_manage_calendars?
        redirect_to master_company_holidays_path, alert: "行事の編集権限がありません"
      end
    end

    def can_manage_calendars?
      current_employee&.admin? || current_employee&.role == "management"
    end
    helper_method :can_manage_calendars?

    def event_json(event)
      {
        id: event.id,
        date: event.event_date.strftime("%Y-%m-%d"),
        name: event.name,
        description: event.description,
        calendar_type: event.calendar_type,
        color: event.color
      }
    end
  end
end
