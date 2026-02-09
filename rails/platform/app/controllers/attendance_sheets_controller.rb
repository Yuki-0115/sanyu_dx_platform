# frozen_string_literal: true

class AttendanceSheetsController < ApplicationController
  authorize_with :daily_reports

  def index
    # 表示月（デフォルトは今月）
    @current_month = if params[:month].present?
                       Date.parse("#{params[:month]}-01")
                     else
                       Date.current.beginning_of_month
                     end

    @start_date = @current_month.beginning_of_month
    @end_date = @current_month.end_of_month
    @days = (@start_date..@end_date).to_a

    # 正社員一覧
    @regular_employees = Employee.where(employment_type: "regular")
                                 .order(:name)

    # 仮社員一覧（協力会社別にグループ化）
    @temporary_employees = Employee.includes(:partner)
                                   .where(employment_type: "temporary")
                                   .order("partners.name", :name)

    # 協力会社一覧（仮社員を持つ会社のみ）
    @partners_with_temporary = Partner.joins(:employees)
                                      .where(employees: { employment_type: "temporary" })
                                      .distinct
                                      .order(:name)

    # この月の全出面データを取得（日報から）
    @attendances = Attendance.joins(:daily_report)
                             .where(daily_reports: { report_date: @start_date..@end_date })
                             .where.not(employee_id: nil)
                             .includes(:employee, daily_report: :project)

    # 社員ID → 日付 → 出面データ のマッピング
    @attendance_map = {}
    @attendances.each do |att|
      @attendance_map[att.employee_id] ||= {}
      @attendance_map[att.employee_id][att.daily_report.report_date] ||= []
      @attendance_map[att.employee_id][att.daily_report.report_date] << att
    end

    # 正社員の集計データ
    @regular_summary = calculate_summary(@regular_employees)

    # 仮社員の集計データ
    @temporary_summary = calculate_summary(@temporary_employees)

    # 協力会社別の集計データ
    @partner_summaries = calculate_partner_summaries

    # 外注稼働データ（原価管理用）- OutsourcingEntryから取得
    @outsourcing_data = calculate_outsourcing_data

    # 全体サマリー
    @total_summary = {
      regular_count: @regular_employees.count,
      temporary_count: @temporary_employees.count,
      regular_man_days: @regular_summary.values.sum { |s| s[:total_days] },
      temporary_man_days: @temporary_summary.values.sum { |s| s[:total_days] },
      outsourcing_companies: @outsourcing_data.size,
      outsourcing_man_days: @outsourcing_data.values.sum { |d| d[:total_man_days] }
    }
  end

  def export_employee
    @employee = Employee.find(params[:employee_id])
    setup_employee_data

    respond_to do |format|
      format.csv do
        send_data generate_employee_csv, filename: "勤怠詳細_#{@employee.name}_#{@current_month.strftime('%Y%m')}.csv", type: "text/csv; charset=utf-8"
      end
    end
  end

  def export_all
    setup_index_data

    respond_to do |format|
      format.csv do
        send_data generate_all_employees_csv, filename: "勤怠管理表_#{@current_month.strftime('%Y%m')}.csv", type: "text/csv; charset=utf-8"
      end
    end
  end

  def project_detail
    @project = Project.find(params[:project_id])
    setup_project_data
  end

  def export_project
    @project = Project.find(params[:project_id])
    setup_project_data

    respond_to do |format|
      format.csv do
        send_data generate_project_csv, filename: "現場別勤怠_#{@project.name.gsub(/[\/\\]/, '_')}_#{@current_month.strftime('%Y%m')}.csv", type: "text/csv; charset=utf-8"
      end
    end
  end

  def employee_detail
    @employee = Employee.find(params[:employee_id])
    setup_employee_data

    # 正社員の場合、確定給与データを取得
    if @employee.employment_type == "regular"
      @monthly_salary = MonthlySalary.find_or_initialize_by(
        employee_id: @employee.id,
        year: @current_month.year,
        month: @current_month.month
      )
    end
  end

  def update_salary
    @employee = Employee.find(params[:employee_id])
    @current_month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.current.beginning_of_month

    @monthly_salary = MonthlySalary.find_or_initialize_by(
      employee_id: @employee.id,
      year: @current_month.year,
      month: @current_month.month
    )

    amount = normalize_number(params[:total_amount])
    if amount.zero? && params[:total_amount].blank?
      @monthly_salary.destroy if @monthly_salary.persisted?
      redirect_to employee_detail_attendance_sheets_path(employee_id: @employee.id, month: @current_month.strftime("%Y-%m")),
                  notice: "給与をクリアしました"
    elsif amount.zero?
      @monthly_salary.destroy if @monthly_salary.persisted?
      redirect_to employee_detail_attendance_sheets_path(employee_id: @employee.id, month: @current_month.strftime("%Y-%m")),
                  notice: "給与をクリアしました"
    else
      @monthly_salary.total_amount = amount
      @monthly_salary.note = params[:note]
      if @monthly_salary.save
        redirect_to employee_detail_attendance_sheets_path(employee_id: @employee.id, month: @current_month.strftime("%Y-%m")),
                    notice: "確定給与を保存しました"
      else
        redirect_to employee_detail_attendance_sheets_path(employee_id: @employee.id, month: @current_month.strftime("%Y-%m")),
                    alert: "保存に失敗しました: #{@monthly_salary.errors.full_messages.join(', ')}"
      end
    end
  end

  private

  def setup_employee_data
    # 表示月（デフォルトは今月）
    @current_month = if params[:month].present?
                       Date.parse("#{params[:month]}-01")
                     else
                       Date.current.beginning_of_month
                     end

    @start_date = @current_month.beginning_of_month
    @end_date = @current_month.end_of_month
    @days = (@start_date..@end_date).to_a

    # この社員のこの月の出面データを取得
    @attendances = Attendance.joins(:daily_report)
                             .where(employee_id: @employee.id)
                             .where(daily_reports: { report_date: @start_date..@end_date })
                             .includes(daily_report: :project)
                             .order("daily_reports.report_date")

    # 日付 → 出面データ のマッピング（同じ日に複数ある場合は最長勤務のものを使用）
    @attendance_by_date = {}
    @attendances.group_by { |att| att.daily_report.report_date }.each do |date, daily_atts|
      @attendance_by_date[date] = daily_atts.max_by { |att| att.total_work_minutes }
    end

    # 月間集計
    @summary = calculate_employee_summary
  end

  def setup_project_data
    # 表示月（デフォルトは今月）
    @current_month = if params[:month].present?
                       Date.parse("#{params[:month]}-01")
                     else
                       Date.current.beginning_of_month
                     end

    @start_date = @current_month.beginning_of_month
    @end_date = @current_month.end_of_month
    @days = (@start_date..@end_date).to_a

    # この現場のこの月の出面データを取得
    @attendances = Attendance.joins(:daily_report)
                             .where(daily_reports: { project_id: @project.id, report_date: @start_date..@end_date })
                             .includes(:employee, daily_report: :foreman)
                             .order("daily_reports.report_date", "employees.name")

    # この現場で稼働した社員一覧
    @employees = @attendances.map(&:employee).compact.uniq.sort_by(&:name)

    # 社員ID → 日付 → 出面データ のマッピング
    @attendance_map = {}
    @attendances.each do |att|
      next unless att.employee

      @attendance_map[att.employee_id] ||= {}
      @attendance_map[att.employee_id][att.daily_report.report_date] ||= []
      @attendance_map[att.employee_id][att.daily_report.report_date] << att
    end

    # 社員ごとの集計
    @employee_summary = calculate_summary(@employees)

    # 外注稼働データ（この現場のみ）
    @outsourcing_entries = OutsourcingEntry
                            .joins(:daily_report)
                            .where(daily_reports: { project_id: @project.id, report_date: @start_date..@end_date })
                            .includes(:partner, :daily_report)

    # 外注会社別 → 日付 → データ のマッピング
    @outsourcing_map = {}
    @outsourcing_entries.each do |entry|
      company = entry.company_name
      next if company.blank?

      @outsourcing_map[company] ||= { days: {}, total_man_days: 0 }
      date = entry.daily_report.report_date
      @outsourcing_map[company][:days][date] ||= { headcount: 0, man_days: 0 }
      @outsourcing_map[company][:days][date][:headcount] += entry.headcount
      @outsourcing_map[company][:days][date][:man_days] += entry.man_days
    end

    @outsourcing_map.each do |_company, data|
      data[:total_man_days] = data[:days].values.sum { |d| d[:man_days] }
    end

    # 現場合計
    @project_summary = {
      employee_count: @employees.count,
      employee_man_days: @employee_summary.values.sum { |s| s[:total_days] },
      outsourcing_companies: @outsourcing_map.size,
      outsourcing_man_days: @outsourcing_map.values.sum { |d| d[:total_man_days] }
    }
  end

  def setup_index_data
    @current_month = if params[:month].present?
                       Date.parse("#{params[:month]}-01")
                     else
                       Date.current.beginning_of_month
                     end

    @start_date = @current_month.beginning_of_month
    @end_date = @current_month.end_of_month
    @days = (@start_date..@end_date).to_a

    @regular_employees = Employee.where(employment_type: "regular").order(:name)
    @temporary_employees = Employee.includes(:partner)
                                   .where(employment_type: "temporary")
                                   .order("partners.name", :name)

    @attendances = Attendance.joins(:daily_report)
                             .where(daily_reports: { report_date: @start_date..@end_date })
                             .where.not(employee_id: nil)
                             .includes(:employee, daily_report: :project)

    @attendance_map = {}
    @attendances.each do |att|
      @attendance_map[att.employee_id] ||= {}
      @attendance_map[att.employee_id][att.daily_report.report_date] ||= []
      @attendance_map[att.employee_id][att.daily_report.report_date] << att
    end

    @regular_summary = calculate_summary(@regular_employees)
    @temporary_summary = calculate_summary(@temporary_employees)
  end

  require "csv"

  def generate_employee_csv
    bom = "\uFEFF"
    csv_data = CSV.generate do |csv|
      # ヘッダー情報
      csv << ["勤怠詳細", @employee.name, @current_month.strftime("%Y年%m月")]
      csv << []

      # 集計情報
      csv << ["月間集計"]
      csv << %w[出勤日数 公休 有給 欠勤 振休 基本時間 残業時間 深夜時間 合計時間 移動距離(km)]
      csv << [
        @summary[:work_days],
        @summary[:day_off_days],
        @summary[:paid_leave_days],
        @summary[:absence_days],
        @summary[:substitute_holiday_days],
        format("%.1f", @summary[:total_regular_hours]),
        format("%.1f", @summary[:total_overtime_hours]),
        format("%.1f", @summary[:total_night_hours]),
        format("%.1f", @summary[:total_work_hours]),
        @summary[:total_travel_distance]
      ]
      csv << []

      # 日別データヘッダー
      csv << %w[日 曜日 区分 出社 退社 休憩(分) 基本(分) 残業(分) 深夜(分) 合計(分) 移動(km) 現場]

      # 日別データ
      @days.each do |date|
        att = @attendance_by_date[date]
        wday = %w[日 月 火 水 木 金 土][date.wday]

        if att.present?
          site = att.site_note.presence || att.daily_report&.project&.name || att.daily_report&.external_site_name || ""
          csv << [
            date.day,
            wday,
            att.work_category_label,
            att.start_time&.strftime("%H:%M") || "",
            att.end_time&.strftime("%H:%M") || "",
            att.break_minutes || "",
            att.work_category == "work" ? att.regular_work_minutes : "",
            att.overtime_minutes || "",
            att.night_minutes || "",
            att.work_category == "work" ? att.total_work_minutes : "",
            att.travel_distance || "",
            site
          ]
        else
          csv << [date.day, wday, "", "", "", "", "", "", "", "", "", ""]
        end
      end
    end
    bom + csv_data
  end

  def generate_all_employees_csv
    bom = "\uFEFF"
    csv_data = CSV.generate do |csv|
      # ヘッダー情報
      csv << ["勤怠管理表", @current_month.strftime("%Y年%m月")]
      csv << []

      # 正社員セクション
      csv << ["正社員"]
      header = ["氏名"] + @days.map(&:day) + %w[出勤 半日 人日]
      csv << header

      @regular_employees.each do |emp|
        row = [emp.name]
        @days.each do |day|
          atts = @attendance_map.dig(emp.id, day) || []
          status = day_attendance_status(atts)
          row << (status == "full" ? "1" : (status == "half" ? "0.5" : ""))
        end
        s = @regular_summary[emp.id] || { full_days: 0, half_days: 0, total_days: 0 }
        row += [s[:full_days], s[:half_days], s[:total_days]]
        csv << row
      end

      csv << []

      # 仮社員セクション
      csv << ["仮社員"]
      csv << header

      @temporary_employees.each do |emp|
        row = [emp.name]
        @days.each do |day|
          atts = @attendance_map.dig(emp.id, day) || []
          status = day_attendance_status(atts)
          row << (status == "full" ? "1" : (status == "half" ? "0.5" : ""))
        end
        s = @temporary_summary[emp.id] || { full_days: 0, half_days: 0, total_days: 0 }
        row += [s[:full_days], s[:half_days], s[:total_days]]
        csv << row
      end
    end
    bom + csv_data
  end

  def generate_project_csv
    bom = "\uFEFF"
    csv_data = CSV.generate do |csv|
      # ヘッダー情報
      csv << ["現場別勤怠", @project.name, @current_month.strftime("%Y年%m月")]
      csv << ["案件コード", @project.code]
      csv << ["顧客", @project.client&.name]
      csv << []

      # サマリー
      csv << ["集計"]
      csv << ["社員稼働人数", @project_summary[:employee_count], "名"]
      csv << ["社員合計人日", @project_summary[:employee_man_days], "人日"]
      csv << ["外注会社数", @project_summary[:outsourcing_companies], "社"]
      csv << ["外注合計人日", @project_summary[:outsourcing_man_days], "人日"]
      csv << []

      # 社員セクション
      csv << ["社員出面"]
      header = ["氏名", "雇用区分"] + @days.map(&:day) + %w[出勤 半日 人日]
      csv << header

      @employees.each do |emp|
        row = [emp.name, emp.employment_type == "regular" ? "正社員" : "仮社員"]
        @days.each do |day|
          atts = @attendance_map.dig(emp.id, day) || []
          status = day_attendance_status(atts)
          row << (status == "full" ? "1" : (status == "half" ? "0.5" : ""))
        end
        s = @employee_summary[emp.id] || { full_days: 0, half_days: 0, total_days: 0 }
        row += [s[:full_days], s[:half_days], s[:total_days]]
        csv << row
      end

      csv << []

      # 外注セクション
      if @outsourcing_map.any?
        csv << ["外注稼働"]
        outsourcing_header = ["協力会社"] + @days.map(&:day) + ["合計人日"]
        csv << outsourcing_header

        @outsourcing_map.each do |company, data|
          row = [company]
          @days.each do |day|
            day_data = data[:days][day]
            row << (day_data ? day_data[:man_days] : "")
          end
          row << data[:total_man_days]
          csv << row
        end
      end
    end
    bom + csv_data
  end

  # 1日の出勤状況を判定（複数現場でも1日としてカウント）
  def day_attendance_status(attendances)
    return nil if attendances.blank?

    if attendances.any? { |a| a.attendance_type == "full" }
      "full"
    elsif attendances.any? { |a| a.attendance_type == "half" }
      "half"
    else
      nil
    end
  end

  def calculate_summary(employees)
    summary = {}

    employees.each do |employee|
      emp_attendances = @attendance_map[employee.id] || {}

      full_days = 0
      half_days = 0

      emp_attendances.each do |_date, atts|
        status = day_attendance_status(atts)
        case status
        when "full"
          full_days += 1
        when "half"
          half_days += 1
        end
      end

      summary[employee.id] = {
        full_days: full_days,
        half_days: half_days,
        working_days: full_days + half_days,
        total_days: full_days + (half_days * 0.5)
      }
    end

    summary
  end

  # 協力会社別の仮社員集計
  def calculate_partner_summaries
    summaries = {}

    @partners_with_temporary.each do |partner|
      partner_employees = @temporary_employees.select { |e| e.partner_id == partner.id }
      partner_summary = partner_employees.map { |e| @temporary_summary[e.id] }

      summaries[partner.id] = {
        name: partner.name,
        employee_count: partner_employees.count,
        full_days: partner_summary.sum { |s| s[:full_days] },
        half_days: partner_summary.sum { |s| s[:half_days] },
        total_days: partner_summary.sum { |s| s[:total_days] }
      }
    end

    summaries
  end

  # 外注稼働データを計算（原価管理用）- OutsourcingEntryから取得
  def calculate_outsourcing_data
    outsourcing_map = {}

    outsourcing_entries = OutsourcingEntry
                          .joins(:daily_report)
                          .where(daily_reports: { report_date: @start_date..@end_date })
                          .includes(:partner, daily_report: :project)

    outsourcing_entries.each do |entry|
      company_name = entry.company_name
      next if company_name.blank?

      outsourcing_map[company_name] ||= { days: {}, total_man_days: 0, partner_id: entry.partner_id }

      date = entry.daily_report.report_date
      outsourcing_map[company_name][:days][date] ||= { full: 0, half: 0 }

      if entry.attendance_type == "full"
        outsourcing_map[company_name][:days][date][:full] += entry.headcount
      else
        outsourcing_map[company_name][:days][date][:half] += entry.headcount
      end
    end

    outsourcing_map.each do |_company_name, data|
      total_full = data[:days].values.sum { |d| d[:full] }
      total_half = data[:days].values.sum { |d| d[:half] }
      data[:total_man_days] = total_full + (total_half * 0.5)
    end

    outsourcing_map
  end

  helper_method :day_attendance_status

  def calculate_employee_summary
    work_days = 0
    day_off_days = 0
    paid_leave_days = 0
    absence_days = 0
    substitute_holiday_days = 0

    total_regular_minutes = 0
    total_overtime_minutes = 0
    total_night_minutes = 0
    total_break_minutes = 0
    total_travel_distance = 0

    # 同じ日に複数の出面がある場合、最も長い勤務時間のレコードを使用
    # 日付ごとにグループ化して代表レコードを選択
    attendances_by_date = @attendances.group_by { |att| att.daily_report.report_date }

    attendances_by_date.each do |_date, daily_attendances|
      # 出勤区分を集計（1日につき1回のみカウント）
      primary_att = daily_attendances.max_by { |att| att.total_work_minutes }

      case primary_att.work_category
      when "work"
        # 1日 or 半日を判定（複数現場でも1日は1日）
        if daily_attendances.any? { |a| a.attendance_type == "full" }
          work_days += 1
        elsif daily_attendances.any? { |a| a.attendance_type == "half" }
          work_days += 0.5
        end
      when "day_off"
        day_off_days += 1
      when "paid_leave"
        paid_leave_days += 1
      when "absence"
        absence_days += 1
      when "substitute_holiday"
        substitute_holiday_days += 1
      end

      # 時間は代表レコード（最も長い勤務）のみを集計
      total_regular_minutes += primary_att.regular_work_minutes
      total_overtime_minutes += (primary_att.overtime_minutes || 0)
      total_night_minutes += (primary_att.night_minutes || 0)
      total_break_minutes += (primary_att.break_minutes || 0)

      # 移動距離は全てのレコードを合算（複数現場の場合）
      daily_attendances.each do |att|
        total_travel_distance += (att.travel_distance || 0)
      end
    end

    {
      work_days: work_days,
      day_off_days: day_off_days,
      paid_leave_days: paid_leave_days,
      absence_days: absence_days,
      substitute_holiday_days: substitute_holiday_days,
      total_regular_hours: total_regular_minutes / 60.0,
      total_overtime_hours: total_overtime_minutes / 60.0,
      total_night_hours: total_night_minutes / 60.0,
      total_break_hours: total_break_minutes / 60.0,
      total_work_hours: (total_regular_minutes + total_overtime_minutes + total_night_minutes) / 60.0,
      total_travel_distance: total_travel_distance
    }
  end
end
