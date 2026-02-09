# frozen_string_literal: true

require "prawn"
require "prawn/table"

# 年次有給休暇管理簿PDF生成サービス
class PaidLeavePdfService
  # システムにインストールされたIPAゴシックフォントを使用
  FONT_PATH = "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf"

  def initialize(employee)
    @employee = employee
    @pdf = Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: 25)
    setup_font
  end

  def generate
    draw_title
    draw_header_info
    @pdf.move_down 10
    draw_two_columns
    draw_footer
    @pdf.render
  end

  private

  def setup_font
    return unless File.exist?(FONT_PATH)

    begin
      @pdf.font_families.update("IPA" => {
        normal: FONT_PATH,
        bold: FONT_PATH
      })
      @pdf.font("IPA")
    rescue StandardError => e
      Rails.logger.warn "Failed to load font: #{e.message}"
    end
  end

  def draw_title
    @pdf.text "年次有給休暇管理簿", size: 20, style: :bold, align: :center
    @pdf.move_down 15
  end

  def draw_header_info
    data = [
      ["社名", "株式会社サンユウテック", "氏名", @employee.name, "入社日", @employee.hire_date&.strftime("%Y/%m/%d") || "-", "作成日", Date.current.strftime("%Y/%m/%d")]
    ]

    @pdf.table(data, cell_style: { size: 9, padding: [6, 8], valign: :center, align: :center }) do |t|
      t.columns([0, 2, 4, 6]).background_color = "EEEEEE"
      t.columns(0).width = 45  # 社名ラベル
      t.columns(1).width = 140 # 株式会社サンユウテック
      t.columns(2).width = 45  # 氏名ラベル
      t.columns(3).width = 90  # 氏名値
      t.columns(4).width = 50  # 入社日ラベル
      t.columns(5).width = 80  # 入社日値
      t.columns(6).width = 50  # 作成日ラベル
      t.columns(7).width = 80  # 作成日値
    end
  end

  def draw_two_columns
    top_position = @pdf.cursor

    # 左カラム（付与情報・集計）
    @pdf.bounding_box([0, top_position], width: 250, height: 400) do
      draw_grant_info
      @pdf.move_down 15
      draw_summary
      @pdf.move_down 10
      @pdf.text "【区分】全休 / 午前半休 / 午後半休", size: 8, color: "666666"
    end

    # 右カラム（取得記録）
    @pdf.bounding_box([270, top_position], width: 520, height: 400) do
      draw_records
    end
  end

  def draw_grant_info
    grants = @employee.paid_leave_grants.order(grant_date: :desc).limit(4)

    @pdf.text "付与情報", size: 11, style: :bold
    @pdf.move_down 5

    data = [["年度", "付与日", "期限", "付与", "使用", "残"]]
    4.times do |i|
      grant = grants[i]
      data << [
        grant&.fiscal_year.to_s.presence || " ",
        grant&.grant_date&.strftime("%m/%d") || " ",
        grant&.expiry_date&.strftime("%m/%d") || " ",
        grant&.granted_days.to_s.presence || " ",
        grant&.used_days.to_s.presence || " ",
        grant&.remaining_days.to_s.presence || " "
      ]
    end

    @pdf.table(data, column_widths: [40, 40, 40, 40, 40, 40], cell_style: { size: 8, padding: 3, align: :center }) do |t|
      t.row(0).background_color = "DDDDDD"
      t.row(0).font_style = :bold
    end
  end

  def draw_summary
    base_date = @employee.paid_leave_base_date || (@employee.hire_date && (@employee.hire_date + 6.months))
    period_start = calculate_period_start(base_date)
    period_end = period_start ? period_start + 1.year - 1.day : Date.current

    grants = @employee.paid_leave_grants.order(grant_date: :desc).limit(4)
    current_year_grant = grants.find { |g| period_start && g.grant_date >= period_start }
    previous_year_grant = grants.find { |g| period_start && g.grant_date < period_start && g.expiry_date > Date.current }

    total_taken = @employee.paid_leave_requests
                           .approved
                           .where(leave_date: (period_start || 1.year.ago)..period_end)
                           .sum(:consumed_days)

    remaining_current = current_year_grant&.remaining_days || 0
    remaining_previous = previous_year_grant&.remaining_days || 0
    remaining_total = remaining_current + remaining_previous
    obligation_met = total_taken >= 5

    @pdf.text "集計", size: 11, style: :bold
    @pdf.move_down 5

    data = [
      ["年間取得日数", "#{total_taken}日"],
      ["取得義務(5日)", obligation_met ? "達成" : "未達"],
      ["残（当年度）", "#{remaining_current}日"],
      ["残（前年度）", "#{remaining_previous}日"],
      ["残（合計）", "#{remaining_total}日"]
    ]

    @pdf.table(data, width: 240, cell_style: { size: 9, padding: 4 }) do |t|
      t.columns(0).background_color = "EEEEEE"
      t.columns(0).width = 120
      t.row(1).columns(1).background_color = obligation_met ? "D4EDDA" : "F8D7DA"
      t.row(4).background_color = "FFFACD"
    end
  end

  def draw_records
    requests = @employee.paid_leave_requests.approved.order(leave_date: :asc).limit(20)

    base_date = @employee.paid_leave_base_date || (@employee.hire_date && (@employee.hire_date + 6.months))
    period_start = calculate_period_start(base_date)

    grants = @employee.paid_leave_grants.order(grant_date: :desc).limit(4)
    current_year_grant = grants.find { |g| period_start && g.grant_date >= period_start }
    previous_year_grant = grants.find { |g| period_start && g.grant_date < period_start && g.expiry_date > Date.current }

    # 累積残日数計算用（付与時点からスタート）
    running_current = current_year_grant&.granted_days.to_f
    running_previous = previous_year_grant&.granted_days.to_f

    @pdf.text "取得記録", size: 11, style: :bold
    @pdf.move_down 5

    data = [["No", "取得日", "区分", "日数", "残当年", "残前年", "残計", "備考"]]

    20.times do |i|
      req = requests[i]
      if req
        consumed = req.consumed_days.to_f
        # 前年度から先に消化（FIFO）
        if running_previous >= consumed
          running_previous -= consumed
        else
          from_prev = running_previous
          running_previous = 0
          running_current -= (consumed - from_prev)
        end
      end

      data << [
        (i + 1).to_s,
        req&.leave_date&.strftime("%Y/%m/%d") || "",
        req&.leave_type_label || "",
        req ? req.consumed_days.to_s : "",
        req ? format("%.1f", running_current) : "",
        req ? format("%.1f", running_previous) : "",
        req ? format("%.1f", running_current + running_previous) : "",
        req&.reason&.truncate(12) || ""
      ]
    end

    @pdf.table(data, width: 510, cell_style: { size: 8, padding: 3, align: :center }) do |t|
      t.row(0).background_color = "DDDDDD"
      t.row(0).font_style = :bold
      t.columns(0).width = 25
      t.columns(1).width = 70
      t.columns(2).width = 55
      t.columns(3).width = 35
      t.columns(4).width = 50
      t.columns(5).width = 50
      t.columns(6).width = 50
      t.columns(7).width = 175
      t.columns(7).align = :left
    end
  end

  def draw_footer
    @pdf.move_cursor_to 20
    @pdf.stroke_horizontal_rule
    @pdf.move_down 5
    @pdf.text "※年10日以上付与者は年5日以上取得義務（労基法39条7項）　※本管理簿は付与期間終了後3年間保存（労基法施行規則24条の7）", size: 7, color: "666666"
  end

  def calculate_period_start(base_date)
    return nil unless base_date
    return base_date if base_date > Date.current

    years_since_base = ((Date.current - base_date) / 365.25).floor
    current_period_start = base_date + years_since_base.years
    current_period_start > Date.current ? current_period_start - 1.year : current_period_start
  end
end
