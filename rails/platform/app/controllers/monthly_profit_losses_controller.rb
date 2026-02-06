# frozen_string_literal: true

class MonthlyProfitLossesController < ApplicationController
  before_action :set_period, only: [:show, :confirm_cost, :unconfirm_cost]

  # 会計年度：10月〜9月（9月決算）
  FISCAL_YEAR_START_MONTH = 10

  # 売上計上対象ステータス（請求基準）
  # 請求書発行以降を売上計上対象とする
  INVOICED_STATUSES = %w[invoiced paid closed].freeze

  def index
    # 月別サマリーを表示（直近12ヶ月）
    @months = build_monthly_summary(12)
    @current_fiscal_year = current_fiscal_year
    @fiscal_years = available_fiscal_years
  end

  # 年度別サマリー
  def yearly
    @fiscal_year = params[:fiscal_year]&.to_i || current_fiscal_year
    @months = build_fiscal_year_summary(@fiscal_year)
    @yearly_total = calculate_yearly_total(@months)
    @fiscal_years = available_fiscal_years
  end

  # 推移表（12ヶ月トレンド）
  def trend
    @fiscal_year = params[:fiscal_year]&.to_i || current_fiscal_year
    @months = build_fiscal_year_summary(@fiscal_year)
    @fiscal_years = available_fiscal_years
  end

  # 対比表（前年比較）
  def comparison
    @fiscal_year = params[:fiscal_year]&.to_i || current_fiscal_year
    @current_months = build_fiscal_year_summary(@fiscal_year)
    @previous_months = build_fiscal_year_summary(@fiscal_year - 1)
    @comparison = build_comparison_data(@current_months, @previous_months)
    @fiscal_years = available_fiscal_years
  end

  def show
    # 指定月の詳細
    @fixed_costs = MonthlyFixedCost.for_month(@year, @month).ordered
    @fixed_costs_by_category = MonthlyFixedCost.by_category_for_month(@year, @month)
    @fixed_costs_total = MonthlyFixedCost.total_for_month(@year, @month)

    # 案件ごとの売上・原価（日報があった案件）
    all_projects = build_projects_summary_with_status(@year, @month)

    # 請求済みと仕掛かりに分類（表示用）
    @completed_projects = all_projects.select { |p| INVOICED_STATUSES.include?(p[:project].status) }

    # その月の出来高データ
    @monthly_progresses = ProjectMonthlyProgress.for_month(@year, @month).includes(:project).index_by(&:project_id)
    @progress_revenue_total = calculate_monthly_revenue(@year, @month)

    # === 請求（出来高月ベース）===
    # その月の出来高に対する請求書の合計（税抜金額で計算）
    # 出来高は税抜ベースなので、請求額も税抜で比較する
    @invoiced_revenue = Invoice.where(progress_year: @year, progress_month: @month)
                               .where(status: %w[issued paid])
                               .sum(:amount).to_i

    # 請求書の内訳（表示用）
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month
    @invoiced_projects = Invoice.where(progress_year: @year, progress_month: @month)
                                .where(status: %w[issued paid])
                                .includes(:project)
                                .map do |invoice|
      {
        project: invoice.project,
        invoice_number: invoice.invoice_number,
        amount: invoice.amount.to_i,  # 税抜金額
        total_amount: invoice.total_amount.to_i,  # 税込金額（参考）
        issued_date: invoice.issued_date
      }
    end

    # === 当月仕掛かり（当月出来高 - 当月請求）===
    # 出来高ベースで計算（請求 + 仕掛かり = 出来高 の関係）
    @wip_revenue_total = @progress_revenue_total - @invoiced_revenue

    # 案件別の仕掛かり内訳
    @wip_projects_data = @monthly_progresses.values.map do |progress|
      monthly_amount = progress.monthly_progress_amount
      next if monthly_amount <= 0

      # この案件の当月出来高に対する請求（税抜）
      project_invoiced = Invoice.where(project_id: progress.project_id, progress_year: @year, progress_month: @month)
                                .where(status: %w[issued paid])
                                .sum(:amount).to_i
      wip_amount = monthly_amount - project_invoiced
      next if wip_amount <= 0

      {
        project: progress.project,
        monthly_progress: monthly_amount,
        invoiced: project_invoiced,
        wip_amount: wip_amount
      }
    end.compact

    # 日報ベースの原価（全案件）
    @estimated_labor_cost = all_projects.sum { |p| p[:labor_cost] }
    @total_outsourcing_man_days_cost = all_projects.sum { |p| p[:outsourcing_man_days_cost] }
    @total_outsourcing_contract_cost = all_projects.sum { |p| p[:outsourcing_contract_cost] }
    @total_material_cost = all_projects.sum { |p| p[:material_cost] }
    @total_expense_cost = all_projects.sum { |p| p[:expense_cost] }

    # 確定給与の確認
    @salary_confirmed = MonthlySalary.confirmed_for_month?(@year, @month)
    @confirmed_salary_total = MonthlySalary.total_for_month(@year, @month)

    # 労務費：確定給与があればそれを使用、なければ概算
    @total_labor_cost = @salary_confirmed ? @confirmed_salary_total : @estimated_labor_cost
    @labor_cost_difference = @confirmed_salary_total - @estimated_labor_cost if @salary_confirmed

    # 確定外注費の確認
    @outsourcing_confirmed = MonthlyOutsourcingCost.confirmed_for_month?(@year, @month)
    @confirmed_outsourcing_total = MonthlyOutsourcingCost.total_for_month(@year, @month)
    @confirmed_outsourcing_by_partner = MonthlyOutsourcingCost.totals_by_partner_for_month(@year, @month)

    # 外注費（概算）
    @estimated_outsourcing_cost = @total_outsourcing_man_days_cost + @total_outsourcing_contract_cost

    # 原価カテゴリ別詳細（展開用）
    @labor_details = build_labor_details(@year, @month)
    @outsourcing_details = build_outsourcing_details(@year, @month)
    @material_details = build_material_details(@year, @month)
    @expense_details = build_expense_details(@year, @month)

    # 外注費：確定があればそれを使用、なければ概算
    @total_outsourcing_cost = @outsourcing_confirmed ? @confirmed_outsourcing_total : @estimated_outsourcing_cost
    @outsourcing_cost_difference = @confirmed_outsourcing_total - @estimated_outsourcing_cost if @outsourcing_confirmed

    # 変動費合計
    @total_variable_cost = @total_labor_cost + @total_outsourcing_cost + @total_material_cost + @total_expense_cost

    # 原価合計
    @total_cost = @total_variable_cost + @fixed_costs_total

    # === 出来高ベース（経営指標用）===
    # その月の出来高から粗利を計算
    @progress_gross_profit = @progress_revenue_total - @total_cost
    @progress_profit_rate = @progress_revenue_total.positive? ? ((@progress_gross_profit.to_d / @progress_revenue_total) * 100).round(1) : 0

    # === 請求ベース（会計確定用）===
    # その月の請求額から粗利を計算
    @invoiced_gross_profit = @invoiced_revenue - @total_cost
    @invoiced_profit_rate = @invoiced_revenue.positive? ? ((@invoiced_gross_profit.to_d / @invoiced_revenue) * 100).round(1) : 0

    # 材料費・経費の確認ステータス
    @material_confirmed = MonthlyCostConfirmation.material_confirmed?(@year, @month)
    @expense_confirmed = MonthlyCostConfirmation.expense_confirmed?(@year, @month)
  end

  # 材料費・経費の確認
  def confirm_cost
    cost_type = params[:cost_type]
    unless MonthlyCostConfirmation::COST_TYPES.include?(cost_type)
      redirect_to monthly_profit_loss_path(year: @year, month: @month), alert: "無効な費用種別です"
      return
    end

    MonthlyCostConfirmation.confirm!(@year, @month, cost_type, current_employee)
    label = MonthlyCostConfirmation::COST_TYPE_LABELS[cost_type]
    redirect_to monthly_profit_loss_path(year: @year, month: @month), notice: "#{@year}年#{@month}月の#{label}を確認済みにしました"
  end

  # 材料費・経費の確認解除
  def unconfirm_cost
    cost_type = params[:cost_type]
    unless MonthlyCostConfirmation::COST_TYPES.include?(cost_type)
      redirect_to monthly_profit_loss_path(year: @year, month: @month), alert: "無効な費用種別です"
      return
    end

    MonthlyCostConfirmation.unconfirm!(@year, @month, cost_type)
    label = MonthlyCostConfirmation::COST_TYPE_LABELS[cost_type]
    redirect_to monthly_profit_loss_path(year: @year, month: @month), notice: "#{@year}年#{@month}月の#{label}の確認を解除しました"
  end

  private

  def set_period
    @year = params[:year].to_i
    @month = params[:month].to_i

    # 無効な年月の場合は今月にリダイレクト
    if @year < 2000 || @month < 1 || @month > 12
      redirect_to monthly_profit_loss_path(year: Date.current.year, month: Date.current.month)
    end
  end

  def build_monthly_summary(months_count)
    result = []
    date = Date.current.beginning_of_month

    months_count.times do
      year = date.year
      month = date.month

      # その月の売上・原価を集計
      revenue = calculate_monthly_revenue(year, month)
      variable_cost = calculate_monthly_variable_cost(year, month)
      fixed_cost = MonthlyFixedCost.total_for_month(year, month)
      total_cost = variable_cost + fixed_cost
      gross_profit = revenue - total_cost
      profit_rate = revenue.positive? ? ((gross_profit.to_d / revenue) * 100).round(1) : 0

      result << {
        year: year,
        month: month,
        label: "#{year}年#{month}月",
        revenue: revenue,
        variable_cost: variable_cost,
        fixed_cost: fixed_cost,
        total_cost: total_cost,
        gross_profit: gross_profit,
        profit_rate: profit_rate
      }

      date = date.prev_month
    end

    result
  end

  def build_projects_summary(year, month)
    build_projects_summary_with_status(year, month)
  end

  def build_projects_summary_with_status(year, month)
    # その月に日報がある案件を取得
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    project_ids = DailyReport.where(report_date: start_date..end_date)
                             .where(status: %w[confirmed revised])
                             .distinct.pluck(:project_id)

    Project.where(id: project_ids).map do |project|
      # その月の原価を内訳付きで計算
      cost_breakdown = calculate_project_monthly_cost_breakdown(project, start_date, end_date)
      total_cost = cost_breakdown.values.sum

      {
        project: project,
        revenue: project.order_amount || 0,
        labor_cost: cost_breakdown[:labor],
        outsourcing_man_days_cost: cost_breakdown[:outsourcing_man_days],
        outsourcing_contract_cost: cost_breakdown[:outsourcing_contract],
        material_cost: cost_breakdown[:material],
        expense_cost: cost_breakdown[:expense],
        cost: total_cost,
        gross_profit: (project.order_amount || 0) - total_cost
      }
    end.sort_by { |p| -p[:cost] }
  end

  # 労務費詳細（社員別）
  def build_labor_details(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    # 確定給与がある場合はそれを表示
    if MonthlySalary.confirmed_for_month?(year, month)
      MonthlySalary.for_month(year, month)
                   .for_regular_employees
                   .includes(:employee)
                   .map do |salary|
        {
          name: salary.employee.name,
          amount: salary.total_amount.to_i,
          type: :confirmed
        }
      end.sort_by { |d| -d[:amount] }
    else
      # 概算（日報ベース）
      employee_costs = {}
      DailyReport.where(report_date: start_date..end_date)
                 .where(status: %w[confirmed revised])
                 .includes(:project, attendances: :employee)
                 .find_each do |report|
        next unless report.project

        project = report.project
        next unless project

        report.attendances.joins(:employee)
              .where(employees: { employment_type: "regular" })
              .includes(:employee)
              .each do |att|
          days = att.attendance_type == "full" ? 1 : 0.5
          cost = (project.regular_labor_unit_price * days).round(0)
          employee_costs[att.employee.name] ||= 0
          employee_costs[att.employee.name] += cost
        end
      end
      employee_costs.map { |name, amount| { name: name, amount: amount, type: :estimated } }
                    .sort_by { |d| -d[:amount] }
    end
  end

  # 外注費詳細（会社別）
  def build_outsourcing_details(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    company_costs = {}
    OutsourcingEntry.joins(:daily_report)
                    .where(daily_reports: { report_date: start_date..end_date, status: %w[confirmed revised] })
                    .includes(:partner, daily_report: :project)
                    .find_each do |entry|
      project = entry.daily_report.project
      next unless project

      company_name = entry.company_name
      company_costs[company_name] ||= { man_days: 0, contract: 0 }

      if entry.billing_type == "man_days"
        days = entry.attendance_type == "full" ? entry.headcount : entry.headcount * 0.5
        company_costs[company_name][:man_days] += (project.outsourcing_unit_price * days).round(0)
      else
        company_costs[company_name][:contract] += entry.contract_amount.to_i
      end
    end

    company_costs.map do |name, costs|
      { name: name, man_days: costs[:man_days], contract: costs[:contract], total: costs[:man_days] + costs[:contract] }
    end.sort_by { |d| -d[:total] }
  end

  # 材料費詳細（案件別）
  def build_material_details(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    Expense.joins(:daily_report)
           .where(daily_reports: { report_date: start_date..end_date, status: %w[confirmed revised] })
           .where(category: "material", status: "approved")
           .includes(daily_report: :project)
           .group_by { |e| e.daily_report.project&.name || "不明" }
           .map { |project_name, expenses| { name: project_name, amount: expenses.sum(&:amount).to_i } }
           .sort_by { |d| -d[:amount] }
  end

  # 経費詳細（カテゴリ別）
  # 注：machinery_own（自社機械）は固定費（減価償却費）として計上済みのため除外
  def build_expense_details(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    Expense.joins(:daily_report)
           .where(daily_reports: { report_date: start_date..end_date, status: %w[confirmed revised] })
           .where.not(category: %w[material machinery_own])
           .where(status: "approved")
           .group(:category)
           .sum(:amount)
           .map { |category, amount| { name: expense_category_label(category), amount: amount.to_i } }
           .sort_by { |d| -d[:amount] }
  end

  def expense_category_label(category)
    {
      "material" => "材料費",
      "transport" => "運搬費",
      "equipment" => "機材費",
      "rental" => "リース・レンタル",
      "machinery_own" => "機械（自社）",
      "machinery_rental" => "機械（レンタル）",
      "consumable" => "消耗品",
      "meal" => "飲食費",
      "fuel" => "燃料費",
      "highway_toll" => "高速代",
      "highway" => "高速代",
      "parking" => "駐車場代",
      "accommodation" => "宿泊費",
      "equipment_rental" => "機材リース",
      "other" => "その他"
    }[category] || category
  end

  def calculate_monthly_revenue(year, month)
    # 出来高ベースの売上（当月出来高 = 累計 - 前月累計）
    current_progresses = ProjectMonthlyProgress.for_month(year, month)

    # 出来高が入力されていない場合は請求ベースにフォールバック
    if current_progresses.empty?
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
      return Invoice.where(issued_date: start_date..end_date)
                    .where(status: %w[issued paid])
                    .sum(:amount).to_i
    end

    # 当月出来高（累計 - 前月累計）の合計
    total = 0
    prev_date = Date.new(year, month, 1).prev_month
    prev_progresses = ProjectMonthlyProgress.for_month(prev_date.year, prev_date.month)
                                            .index_by(&:project_id)

    current_progresses.each do |progress|
      prev_amount = prev_progresses[progress.project_id]&.progress_amount || 0
      monthly_amount = progress.progress_amount - prev_amount
      total += monthly_amount if monthly_amount.positive?
    end

    total.to_i
  end

  def calculate_monthly_variable_cost(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    # その月の日報から原価を集計
    reports = DailyReport.where(report_date: start_date..end_date)
                         .where(status: %w[confirmed revised])
                         .includes(:project)

    total = 0
    reports.find_each do |report|
      total += calculate_daily_report_cost(report)
    end
    total
  end

  def calculate_daily_report_cost(report)
    breakdown = calculate_daily_report_cost_breakdown(report)
    breakdown.values.sum
  end

  def calculate_project_monthly_cost(project, start_date, end_date)
    breakdown = calculate_project_monthly_cost_breakdown(project, start_date, end_date)
    breakdown.values.sum
  end

  def calculate_project_monthly_cost_breakdown(project, start_date, end_date)
    reports = project.daily_reports
                     .where(report_date: start_date..end_date)
                     .where(status: %w[confirmed revised])

    labor = 0
    outsourcing_man_days = 0
    outsourcing_contract = 0
    material = 0
    expense = 0

    reports.find_each do |report|
      breakdown = calculate_daily_report_cost_breakdown(report)
      labor += breakdown[:labor]
      outsourcing_man_days += breakdown[:outsourcing_man_days]
      outsourcing_contract += breakdown[:outsourcing_contract]
      material += breakdown[:material]
      expense += breakdown[:expense]
    end

    {
      labor: labor,
      outsourcing_man_days: outsourcing_man_days,
      outsourcing_contract: outsourcing_contract,
      material: material,
      expense: expense
    }
  end

  def calculate_daily_report_cost_breakdown(report)
    project = report.project

    # 単価取得（案件がない場合はデフォルト値を使用）
    regular_unit_price = project&.regular_labor_unit_price || 18_000
    outsourcing_unit_price = project&.outsourcing_unit_price || 18_000

    # 労務費（正社員）
    regular_days = report.attendances.joins(:employee)
                         .where(employees: { employment_type: "regular" })
                         .sum("CASE attendance_type WHEN 'full' THEN 1 WHEN 'half' THEN 0.5 ELSE 0 END").to_d
    labor = (regular_unit_price * regular_days).round(0)

    # 外注費（人工）
    outsourcing_days = report.outsourcing_entries
                             .where(billing_type: "man_days")
                             .sum("CASE attendance_type WHEN 'full' THEN headcount WHEN 'half' THEN headcount * 0.5 ELSE 0 END").to_d
    outsourcing_man_days = (outsourcing_unit_price * outsourcing_days).round(0)

    # 外注費（請負）
    outsourcing_contract = report.outsourcing_entries.where(billing_type: "contract").sum(:contract_amount).to_i

    # 経費（カテゴリ別）- 自社機械は固定費として計上済みのため除外
    expenses_by_cat = Expense.where(daily_report_id: report.id, status: "approved")
                             .where.not(category: "machinery_own")
                             .group(:category).sum(:amount)
    material = (expenses_by_cat["material"] || 0).to_i
    expense = expenses_by_cat.except("material").values.sum.to_i

    {
      labor: labor,
      outsourcing_man_days: outsourcing_man_days,
      outsourcing_contract: outsourcing_contract,
      material: material,
      expense: expense
    }
  end

  # 会計年度ヘルパーメソッド

  # 現在の会計年度を取得（10月〜9月）
  def current_fiscal_year
    today = Date.current
    today.month >= FISCAL_YEAR_START_MONTH ? today.year : today.year - 1
  end

  # 利用可能な会計年度リスト
  def available_fiscal_years
    current = current_fiscal_year
    (current - 4..current).to_a.reverse
  end

  # 会計年度の月リストを取得（10月〜9月）
  def fiscal_year_months(fiscal_year)
    months = []
    # 10月〜12月
    (FISCAL_YEAR_START_MONTH..12).each do |month|
      months << { year: fiscal_year, month: month }
    end
    # 1月〜9月
    (1...FISCAL_YEAR_START_MONTH).each do |month|
      months << { year: fiscal_year + 1, month: month }
    end
    months
  end

  # 会計年度のサマリーを構築
  def build_fiscal_year_summary(fiscal_year)
    fiscal_year_months(fiscal_year).map do |period|
      year = period[:year]
      month = period[:month]

      revenue = calculate_monthly_revenue(year, month)
      variable_cost = calculate_monthly_variable_cost_with_salary(year, month)
      fixed_cost = MonthlyFixedCost.total_for_month(year, month)
      total_cost = variable_cost + fixed_cost
      gross_profit = revenue - total_cost
      profit_rate = revenue.positive? ? ((gross_profit.to_d / revenue) * 100).round(1) : 0

      {
        year: year,
        month: month,
        label: "#{month}月",
        full_label: "#{year}年#{month}月",
        revenue: revenue,
        variable_cost: variable_cost,
        fixed_cost: fixed_cost,
        total_cost: total_cost,
        gross_profit: gross_profit,
        profit_rate: profit_rate
      }
    end
  end

  # 確定給与を考慮した変動費計算
  def calculate_monthly_variable_cost_with_salary(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    # 確定給与があればそれを使用
    if MonthlySalary.confirmed_for_month?(year, month)
      labor_cost = MonthlySalary.total_for_month(year, month)
    else
      # 概算（日報ベース）
      labor_cost = calculate_estimated_labor_cost(year, month)
    end

    # その他の変動費
    other_costs = calculate_other_variable_costs(year, month)

    labor_cost + other_costs
  end

  def calculate_estimated_labor_cost(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    reports = DailyReport.where(report_date: start_date..end_date)
                         .where(status: %w[confirmed revised])
                         .includes(:project)

    total = 0
    reports.find_each do |report|
      next unless report.project

      regular_days = report.attendances.joins(:employee)
                           .where(employees: { employment_type: "regular" })
                           .sum("CASE attendance_type WHEN 'full' THEN 1 WHEN 'half' THEN 0.5 ELSE 0 END").to_d
      total += (report.project.regular_labor_unit_price * regular_days).round(0)
    end
    total
  end

  def calculate_other_variable_costs(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    # 確定外注費があればそれを使用
    if MonthlyOutsourcingCost.confirmed_for_month?(year, month)
      outsourcing_cost = MonthlyOutsourcingCost.total_for_month(year, month)
    else
      outsourcing_cost = calculate_estimated_outsourcing_cost(year, month)
    end

    # 経費（材料費含む）
    expense_cost = calculate_expense_cost(year, month)

    outsourcing_cost + expense_cost
  end

  def calculate_estimated_outsourcing_cost(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    total = 0
    DailyReport.where(report_date: start_date..end_date)
               .where(status: %w[confirmed revised])
               .includes(:project)
               .find_each do |report|
      next unless report.project

      # 外注費（人工）
      outsourcing_days = report.outsourcing_entries
                               .where(billing_type: "man_days")
                               .sum("CASE attendance_type WHEN 'full' THEN headcount WHEN 'half' THEN headcount * 0.5 ELSE 0 END").to_d
      total += (report.project.outsourcing_unit_price * outsourcing_days).round(0)

      # 外注費（請負）
      total += report.outsourcing_entries.where(billing_type: "contract").sum(:contract_amount).to_i
    end
    total
  end

  # 経費合計（材料費を除く、自社機械は固定費のため除外）
  def calculate_expense_cost(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month

    Expense.joins(:daily_report)
           .where(daily_reports: { report_date: start_date..end_date, status: %w[confirmed revised] })
           .where.not(category: "machinery_own")
           .where(status: "approved")
           .sum(:amount).to_i
  end

  # 年度合計を計算
  def calculate_yearly_total(months)
    {
      revenue: months.sum { |m| m[:revenue] },
      variable_cost: months.sum { |m| m[:variable_cost] },
      fixed_cost: months.sum { |m| m[:fixed_cost] },
      total_cost: months.sum { |m| m[:total_cost] },
      gross_profit: months.sum { |m| m[:gross_profit] },
      profit_rate: months.sum { |m| m[:revenue] }.positive? ?
        ((months.sum { |m| m[:gross_profit] }.to_d / months.sum { |m| m[:revenue] }) * 100).round(1) : 0
    }
  end

  # 対比データを構築
  def build_comparison_data(current_months, previous_months)
    current_total = calculate_yearly_total(current_months)
    previous_total = calculate_yearly_total(previous_months)

    {
      current: current_total,
      previous: previous_total,
      diff: {
        revenue: current_total[:revenue] - previous_total[:revenue],
        variable_cost: current_total[:variable_cost] - previous_total[:variable_cost],
        fixed_cost: current_total[:fixed_cost] - previous_total[:fixed_cost],
        total_cost: current_total[:total_cost] - previous_total[:total_cost],
        gross_profit: current_total[:gross_profit] - previous_total[:gross_profit]
      },
      rate: {
        revenue: previous_total[:revenue].positive? ?
          (((current_total[:revenue] - previous_total[:revenue]).to_d / previous_total[:revenue]) * 100).round(1) : 0,
        gross_profit: previous_total[:gross_profit].positive? ?
          (((current_total[:gross_profit] - previous_total[:gross_profit]).to_d / previous_total[:gross_profit]) * 100).round(1) : 0
      },
      monthly: current_months.zip(previous_months).map do |current, previous|
        {
          month: current[:month],
          current: current,
          previous: previous,
          diff_revenue: current[:revenue] - previous[:revenue],
          diff_profit: current[:gross_profit] - previous[:gross_profit]
        }
      end
    }
  end
end
