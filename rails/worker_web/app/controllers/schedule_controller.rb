# frozen_string_literal: true

class ScheduleController < ApplicationController
  def index
    @current_week_start = if params[:week].present?
                            Date.parse(params[:week]).beginning_of_week(:sunday)
                          else
                            Date.current.beginning_of_week(:sunday)
                          end
    @week_dates = (0..6).map { |i| @current_week_start + i.days }
    @today = Date.current

    # Active projects
    @projects = Project.where(status: %w[ordered preparing in_progress])
                       .includes(:client)
                       .order(:name)

    # Work schedules for the week
    schedules = WorkSchedule.for_date_range(@week_dates.first..@week_dates.last)
                            .includes(:employee, :project)

    @schedule_map = {}
    schedules.each do |s|
      key = [s.project_id, s.scheduled_date, s.shift]
      @schedule_map[key] ||= []
      @schedule_map[key] << s
    end

    # Outsourcing schedules
    outsourcing = OutsourcingSchedule.for_date_range(@week_dates.first..@week_dates.last)
                                     .includes(:partner, :project)
    @outsourcing_map = {}
    outsourcing.each do |os|
      key = [os.project_id, os.scheduled_date, os.shift]
      @outsourcing_map[key] ||= []
      @outsourcing_map[key] << os
    end

    # Notes
    notes = DailyScheduleNote.for_date_range(@week_dates.first..@week_dates.last)
    @notes_map = notes.index_by { |n| [n.project_id, n.scheduled_date] }

    # Mobile: selected day index
    @selected_day_index = if params[:day].present?
                            params[:day].to_i.clamp(0, 6)
                          else
                            @week_dates.index(@today) || 0
                          end
  end
end
