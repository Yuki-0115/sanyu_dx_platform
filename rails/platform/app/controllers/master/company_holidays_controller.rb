# frozen_string_literal: true

module Master
  class CompanyHolidaysController < ApplicationController
    before_action :authorize_view_access!
    before_action :authorize_edit_access!, except: [:index]
    before_action :set_company_holiday, only: [:destroy]

    def index
      @year = params[:year]&.to_i || Date.current.year
      @calendar_type = params[:calendar_type] || "worker"

      # 事務カレンダーは管理者のみ閲覧可能
      if @calendar_type == "office" && !can_manage_calendars?
        redirect_to master_company_holidays_path(year: @year, calendar_type: "worker"), alert: "事務用カレンダーの閲覧権限がありません"
        return
      end

      @holidays = CompanyHoliday
        .where(calendar_type: @calendar_type)
        .for_year(@year)
        .order(:holiday_date)

      # カレンダー表示用のデータ
      @months = (1..12).map do |month|
        date = Date.new(@year, month, 1)
        {
          month: month,
          name: "#{month}月",
          start_date: date,
          end_date: date.end_of_month,
          weeks: build_weeks(date),
          holiday_dates: @holidays.select { |h| h.holiday_date.month == month }.map(&:holiday_date)
        }
      end

      # 統計
      @total_holidays = @holidays.count
      @other_type = @calendar_type == "worker" ? "office" : "worker"
      @other_count = CompanyHoliday.where(calendar_type: @other_type).for_year(@year).count

      # 年間行事を取得
      @events = CompanyEvent.for_year(@year).for_calendar_type(@calendar_type).order(:event_date, :name)
      @events_by_date = @events.group_by(&:event_date)
    end

    def create
      @company_holiday = CompanyHoliday.new(company_holiday_params)

      if @company_holiday.save
        respond_to do |format|
          format.html { redirect_to master_company_holidays_path(year: @company_holiday.holiday_date.year, calendar_type: @company_holiday.calendar_type), notice: "休日を追加しました" }
          format.json { render json: { success: true, holiday: holiday_json(@company_holiday) } }
        end
      else
        respond_to do |format|
          format.html { redirect_to master_company_holidays_path, alert: @company_holiday.errors.full_messages.join(", ") }
          format.json { render json: { success: false, errors: @company_holiday.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      year = @company_holiday.holiday_date.year
      calendar_type = @company_holiday.calendar_type
      @company_holiday.destroy

      respond_to do |format|
        format.html { redirect_to master_company_holidays_path(year: year, calendar_type: calendar_type), notice: "休日を削除しました" }
        format.json { render json: { success: true } }
      end
    end

    # 日付トグル（クリックで追加/削除）
    def toggle
      date = Date.parse(params[:date])
      calendar_type = params[:calendar_type]
      name = params[:name]

      existing = CompanyHoliday.find_by(holiday_date: date, calendar_type: calendar_type)

      if existing
        existing.destroy
        render json: { success: true, action: "removed", date: date.strftime("%Y-%m-%d") }
      else
        holiday = CompanyHoliday.create(holiday_date: date, calendar_type: calendar_type, name: name)
        if holiday.persisted?
          render json: { success: true, action: "added", date: date.strftime("%Y-%m-%d"), holiday: holiday_json(holiday) }
        else
          render json: { success: false, errors: holiday.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end

    # 一括設定（土日を一括で休日に設定など）
    def bulk_set
      year = params[:year].to_i
      calendar_type = params[:calendar_type]
      action = params[:bulk_action]

      result = case action
      when "add_saturdays"
        count = add_weekdays(year, calendar_type, 6, "土曜日")
        { success: true, message: "#{count}件の土曜日を追加しました" }
      when "add_sundays"
        count = add_weekdays(year, calendar_type, 0, "日曜日")
        { success: true, message: "#{count}件の日曜日を追加しました" }
      when "add_weekends"
        sat_count = add_weekdays(year, calendar_type, 6, "土曜日")
        sun_count = add_weekdays(year, calendar_type, 0, "日曜日")
        { success: true, message: "#{sat_count + sun_count}件の土日を追加しました" }
      when "add_national_holidays"
        add_national_holidays(year, calendar_type)
      when "clear_all"
        count = CompanyHoliday.where(calendar_type: calendar_type).for_year(year).delete_all
        { success: true, message: "#{count}件の休日をクリアしました" }
      else
        { success: false, message: "不明なアクションです" }
      end

      if result[:success]
        redirect_to master_company_holidays_path(year: year, calendar_type: calendar_type), notice: result[:message]
      else
        redirect_to master_company_holidays_path(year: year, calendar_type: calendar_type), alert: result[:message]
      end
    end

    # 他のカレンダーからコピー
    def copy_from
      year = params[:year].to_i
      from_type = params[:from_type]
      to_type = params[:to_type]

      source_holidays = CompanyHoliday.where(calendar_type: from_type).for_year(year)

      copied = 0
      source_holidays.each do |h|
        unless CompanyHoliday.exists?(holiday_date: h.holiday_date, calendar_type: to_type)
          CompanyHoliday.create(holiday_date: h.holiday_date, calendar_type: to_type, name: h.name)
          copied += 1
        end
      end

      redirect_to master_company_holidays_path(year: year, calendar_type: to_type), notice: "#{copied}件の休日をコピーしました"
    end

    private

    def set_company_holiday
      @company_holiday = CompanyHoliday.find(params[:id])
    end

    def company_holiday_params
      params.require(:company_holiday).permit(:holiday_date, :calendar_type, :name, :description)
    end

    # カレンダーの閲覧権限チェック（全社員可能）
    def authorize_view_access!
      unless current_employee
        redirect_to root_path, alert: "ログインが必要です"
      end
    end

    # カレンダーの編集権限チェック（管理者・経営層のみ）
    def authorize_edit_access!
      unless can_manage_calendars?
        redirect_to master_company_holidays_path, alert: "カレンダーの編集権限がありません"
      end
    end

    # 管理者または経営層かどうか
    def can_manage_calendars?
      current_employee&.admin? || current_employee&.role == "management"
    end
    helper_method :can_manage_calendars?

    def build_weeks(date)
      start_date = date.beginning_of_month.beginning_of_week(:sunday)
      end_date = date.end_of_month.end_of_week(:sunday)
      (start_date..end_date).to_a.each_slice(7).to_a
    end

    def add_weekdays(year, calendar_type, wday, name)
      count = 0
      (Date.new(year, 1, 1)..Date.new(year, 12, 31)).each do |date|
        next unless date.wday == wday
        next if CompanyHoliday.exists?(holiday_date: date, calendar_type: calendar_type)

        if CompanyHoliday.create(holiday_date: date, calendar_type: calendar_type, name: name).persisted?
          count += 1
        end
      end
      count
    end

    def add_national_holidays(year, calendar_type)
      unless defined?(HolidayJp)
        Rails.logger.error "HolidayJp gem not available"
        return { success: false, message: "祝日ライブラリが利用できません。サーバーを再起動してください。" }
      end

      begin
        holidays = HolidayJp.between(Date.new(year, 1, 1), Date.new(year, 12, 31))
        count = 0
        holidays.each do |holiday|
          next if CompanyHoliday.exists?(holiday_date: holiday.date, calendar_type: calendar_type)
          if CompanyHoliday.create(holiday_date: holiday.date, calendar_type: calendar_type, name: holiday.name).persisted?
            count += 1
          end
        end
        Rails.logger.info "Added #{count} national holidays for #{year} (#{calendar_type})"
        { success: true, message: "#{count}件の祝日を追加しました" }
      rescue => e
        Rails.logger.error "Failed to add national holidays: #{e.message}"
        { success: false, message: "祝日の追加に失敗しました: #{e.message}" }
      end
    end

    def holiday_json(holiday)
      {
        id: holiday.id,
        date: holiday.holiday_date.strftime("%Y-%m-%d"),
        name: holiday.name,
        calendar_type: holiday.calendar_type
      }
    end
  end
end
