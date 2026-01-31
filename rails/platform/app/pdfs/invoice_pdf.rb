# frozen_string_literal: true

require "prawn"
require "prawn/table"

class InvoicePdf
  include ActionView::Helpers::NumberHelper

  FONT_PATH = Rails.root.join("app/assets/fonts")
  IMAGE_PATH = Rails.root.join("app/assets/images")

  # A4 Landscape: 842 x 595 points
  PAGE_WIDTH = 782  # 842 - 30 - 30 (margins)
  PAGE_HEIGHT = 535 # 595 - 30 - 30 (margins)

  # Colors（ロゴに合わせた配色）
  PRIMARY_COLOR = "F7931E"     # Orange (from logo)
  SECONDARY_COLOR = "00A0E9"   # Blue (from logo)
  ACCENT_COLOR = "2C3E50"      # Dark blue
  LIGHT_BG = "F8F9FA"          # Light gray background
  TOTAL_BG = "FFF3CD"          # Yellow for totals
  LINE_COLOR = "333333"
  BORDER_COLOR = "CCCCCC"

  # Row heights
  ROW_HEIGHT = 16
  HEADER_HEIGHT = 20

  def initialize(invoice)
    @invoice = invoice
    @project = invoice.project
    @client = @project.client
  end

  def document
    @document ||= Prawn::Document.new(
      page_size: "A4",
      page_layout: :landscape,
      margin: [25, 30, 40, 30],
      info: {
        Title: "請求書_#{@invoice.invoice_number}",
        Author: "株式会社 サンユウテック",
        Creator: "SanyuTech DX Platform"
      }
    )
  end

  def render_pdf
    setup_fonts

    # ヘッダー（日付）
    render_header

    # タイトル
    render_title

    # 左：宛先・工事情報、右：会社情報・金額
    render_main_section

    # 明細テーブル
    render_items_table

    # 振込先・支払条件
    render_payment_info

    # フッター
    render_footer

    document.render
  end

  private

  def setup_fonts
    document.font_families.update(
      "IPA" => {
        normal: FONT_PATH.join("ipaexg.ttf").to_s,
        bold: FONT_PATH.join("ipaexg.ttf").to_s
      }
    )
    document.font "IPA"
  end

  def render_header
    # 右上：日付
    document.fill_color "666666"
    document.text "1 / 1 ページ", size: 9, align: :right
    document.fill_color "000000"
    document.move_down 2
    document.text format_date_jp(@invoice.issued_date || Date.current), size: 11, align: :right
    document.move_down 8
  end

  def render_title
    document.fill_color ACCENT_COLOR
    document.text "請　求　書", size: 22, style: :bold, align: :center, character_spacing: 8
    document.fill_color "000000"

    # タイトル下線
    document.move_down 4
    center = PAGE_WIDTH / 2
    document.stroke_color PRIMARY_COLOR
    document.line_width = 2
    document.stroke_horizontal_line center - 80, center + 80
    document.stroke_color LINE_COLOR
    document.line_width = 0.5

    document.move_down 15
  end

  def render_main_section
    top_y = document.cursor

    # 左側：宛先・工事情報
    document.bounding_box([0, top_y], width: 370, height: 170) do
      render_recipient_info
    end

    # 右側：会社情報・金額（ロゴ・角印含む）
    document.bounding_box([390, top_y], width: 390, height: 170) do
      render_company_and_amount
    end

    document.move_cursor_to(top_y - 175)
  end

  def render_recipient_info
    # 宛先
    client_name = @client&.name || "（宛先未設定）"
    document.fill_color ACCENT_COLOR
    document.text "#{client_name}　御中", size: 15, style: :bold
    document.fill_color "000000"

    document.move_down 2
    document.stroke_color PRIMARY_COLOR
    document.line_width = 2
    document.stroke_horizontal_line 0, 310
    document.stroke_color LINE_COLOR
    document.line_width = 0.5

    document.move_down 12

    # 工事情報
    info_items = [
      ["工 事 名", @project.name],
      ["工事場所", @project.site_address],
      ["請求番号", @invoice.invoice_number || "（未発行）"],
      ["支払期限", @invoice.due_date ? format_date_jp(@invoice.due_date) : "-"],
      ["対象期間", progress_period_text]
    ]

    info_items.each do |label, value|
      document.fill_color SECONDARY_COLOR
      document.text_box "【#{label}】", at: [0, document.cursor], width: 75, size: 9
      document.fill_color "000000"
      document.text_box (value.presence || "-"), at: [80, document.cursor], width: 280, size: 9
      document.move_down 13
    end
  end

  def progress_period_text
    if @invoice.progress_year && @invoice.progress_month
      "#{@invoice.progress_year}年#{@invoice.progress_month}月分"
    else
      "-"
    end
  end

  def render_company_and_amount
    company_top = document.cursor
    logo_path = IMAGE_PATH.join("sanyu_logo.png")
    stamp_path = IMAGE_PATH.join("sanyu_stamp.jpg")

    # ロゴ（社名の上・左揃え）
    if File.exist?(logo_path)
      document.image logo_path, at: [70, company_top], width: 90
    end

    # 社名（ロゴの下・1行）
    document.fill_color "000000"
    document.text_box "株式会社 サンユウテック", at: [70, company_top - 38], width: 280, size: 18, style: :bold

    # 角印（右側）
    if File.exist?(stamp_path)
      document.image stamp_path, at: [305, company_top - 5], width: 60, height: 60
    end

    document.move_down 62

    # 住所・連絡先
    document.fill_color "444444"
    document.text "〒816-0912 福岡県大野城市御笠川6丁目2-5", size: 9, align: :center
    document.text "TEL: 092-555-9211  FAX: 092-555-9217", size: 9, align: :center
    document.fill_color "000000"

    document.move_down 6

    # 金額ボックス
    box_x = 5
    box_width = 375
    box_height = 70

    box_top = document.cursor

    document.fill_color LIGHT_BG
    document.fill_rounded_rectangle [box_x, box_top], box_width, box_height, 4
    document.fill_color "000000"

    document.stroke_color PRIMARY_COLOR
    document.line_width = 2
    document.stroke_rounded_rectangle [box_x, box_top], box_width, box_height, 4

    # ボックス内のコンテンツを絶対位置で配置
    content_x = box_x + 12
    content_width = box_width - 24

    # 小計・消費税（ボックス上端から12pt下）
    y_pos = box_top - 14
    document.fill_color "000000"
    document.text_box "小計　#{format_currency(@invoice.amount)}", at: [content_x, y_pos], width: 150, size: 9
    document.text_box "消費税　#{format_currency(@invoice.tax_amount)}", at: [content_x + 150, y_pos], width: 190, size: 9, align: :right

    # 区切り線（ボックス上端から28pt下）
    document.stroke_color PRIMARY_COLOR
    document.line_width = 1
    document.stroke_horizontal_line content_x, content_x + content_width, at: box_top - 28

    # 合計金額（ボックス上端から42pt下）
    y_pos = box_top - 45
    document.fill_color PRIMARY_COLOR
    document.text_box "御請求金額（税込）", at: [content_x, y_pos], width: 120, size: 10, style: :bold
    document.fill_color ACCENT_COLOR
    document.text_box format_currency(@invoice.total_amount), at: [content_x + 120, y_pos], width: content_width - 120, size: 18, style: :bold, align: :right
    document.fill_color "000000"

    document.stroke_color LINE_COLOR
    document.line_width = 0.5
  end

  def render_items_table
    document.move_down 8

    header = ["No.", "名　　称", "仕様・規格・寸法", "数　量", "単位", "単　価", "金　額", "備　考"]
    data = [header]

    # 明細データ
    if @invoice.invoice_items.any?
      @invoice.invoice_items.each_with_index do |item, idx|
        data << [
          (idx + 1).to_s,
          item.name || "",
          item.description || "",
          format_qty(item.quantity),
          item.unit || "式",
          format_num(item.unit_price),
          format_num(item.subtotal),
          ""
        ]
      end
    else
      # 明細がない場合
      data << ["1", "工事一式", "", "1.0", "式", format_num(@invoice.amount), format_num(@invoice.amount), ""]
    end

    items_count = @invoice.invoice_items.any? ? @invoice.invoice_items.count : 1

    # 空行追加（最低4行、最大8行に収める）
    empty_rows = [[4 - items_count, 0].max, 8 - items_count].min
    empty_rows.times { data << ["", "", "", "", "", "", "", ""] }

    # 合計行
    data << ["", "合　計　（税抜）", "", "", "", "", format_num(@invoice.amount), ""]

    # 列幅（全体で740pt程度に収める）
    col_widths = [28, 130, 190, 45, 35, 70, 90, 132]
    table_width = col_widths.sum

    document.table(data, column_widths: col_widths, width: table_width, position: :center, cell_style: { size: 8, padding: [2, 3], height: ROW_HEIGHT, valign: :center }) do |t|
      # ヘッダースタイル
      t.row(0).background_color = PRIMARY_COLOR
      t.row(0).text_color = "FFFFFF"
      t.row(0).font_style = :bold
      t.row(0).align = :center
      t.row(0).height = HEADER_HEIGHT

      # 列の配置
      t.columns(0).align = :center
      t.columns(3..6).align = :right

      # ボーダー
      t.cells.borders = [:top, :bottom, :left, :right]
      t.cells.border_width = 0.5
      t.cells.border_color = BORDER_COLOR

      # 合計行のスタイル
      t.row(-1).background_color = TOTAL_BG
      t.row(-1).font_style = :bold
      t.row(-1).border_color = PRIMARY_COLOR
      t.row(-1).border_width = 1
    end
  end

  def render_payment_info
    document.move_down 10

    # 振込先情報ボックス
    info_width = 500
    info_x = (PAGE_WIDTH - info_width) / 2

    document.fill_color "444444"

    # 振込先
    document.indent(info_x) do
      document.text "【お振込先】", size: 9, style: :bold
      document.move_down 2
      document.text "　福岡銀行 雑餉隈支店 普通 2158511", size: 9
      document.text "　口座名義：株式会社 サンユウテック 代表取締役 渡辺真弘", size: 9
      document.move_down 4
      document.text "登録番号：T9290001061070（適格請求書発行事業者）", size: 8
    end

    document.fill_color "000000"
  end

  def render_footer
    document.bounding_box([0, 28], width: PAGE_WIDTH, height: 20) do
      document.stroke_color "DDDDDD"
      document.stroke_horizontal_line 0, PAGE_WIDTH
      document.move_down 5
      document.fill_color "888888"
      document.text "株式会社 サンユウテック", size: 8, align: :right
      document.fill_color "000000"
    end
  end

  # フォーマットヘルパー
  def format_currency(amount)
    return "¥0" if amount.blank?
    "¥#{number_with_delimiter(amount.to_i)}"
  end

  def format_num(num)
    return "" if num.blank? || num == 0
    number_with_delimiter(num.to_i)
  end

  def format_qty(qty)
    return "" if qty.blank?
    qty.to_f == qty.to_i ? qty.to_i.to_s : format("%.1f", qty)
  end

  def format_date_jp(date)
    return "" if date.blank?
    date.strftime("%Y年%m月%d日")
  end
end
