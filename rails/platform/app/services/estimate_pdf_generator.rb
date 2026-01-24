# frozen_string_literal: true

require "prawn"
require "prawn/table"

class EstimatePdfGenerator
  include ActionView::Helpers::NumberHelper

  FONT_PATH = Rails.root.join("app/assets/fonts")
  # A4 Landscape: 842 x 595 points
  PAGE_WIDTH = 782  # 842 - 30 - 30 (margins)
  PAGE_HEIGHT = 510 # 595 - 25 - 60 (margins, bottom increased for footer)

  # Colors
  PRIMARY_COLOR = "F7941D"     # Orange
  SECONDARY_COLOR = "4A90A4"   # Blue-gray
  ACCENT_COLOR = "2C3E50"      # Dark blue
  LIGHT_BG = "F8F9FA"          # Light gray background
  CATEGORY_BG = "E8E8E8"       # Category row background
  TOTAL_BG = "FFF3CD"          # Yellow for totals
  LINE_COLOR = "333333"
  BORDER_COLOR = "CCCCCC"

  # Row heights
  ROW_HEIGHT = 18
  HEADER_HEIGHT = 22

  # ページヘッダー高さ（ページ番号 + タイトル + 罫線 + 余白 + 安全マージン）
  PAGE_HEADER_HEIGHT = 110

  # テーブルに使える高さ（ページ高さ - ヘッダー高さ）
  AVAILABLE_TABLE_HEIGHT = PAGE_HEIGHT - PAGE_HEADER_HEIGHT

  def initialize(estimate)
    @estimate = estimate
    @project = estimate.project
  end

  def generate
    Prawn::Document.new(
      page_size: "A4",
      page_layout: :landscape,
      margin: [25, 30, 60, 30],  # bottom margin increased for footer
      print_scaling: :none,      # 印刷時に拡大縮小しない
      info: {
        Title: "見積書_#{@estimate.estimate_number}",
        Author: "株式会社 サンユウテック",
        Creator: "SanyuTech DX Platform"
      }
    ) do |pdf|
      setup_fonts(pdf)

      # 1. 表紙
      render_cover(pdf)

      # 2. 内訳明細書（工種ごとにページ分割）
      render_breakdown_pages(pdf)

      # 3. 工事見積確認書（確認データがある場合）
      if @estimate.estimate_confirmations.any?
        pdf.start_new_page
        render_confirmation_page(pdf)
      end

      # 4. 施工条件書（条件がある場合）
      if @estimate.conditions.present?
        pdf.start_new_page
        render_conditions_page(pdf)
      end

      # フッター（全ページ）
      add_footer(pdf)
    end.render
  end

  private

  def setup_fonts(pdf)
    pdf.font_families.update(
      "IPA" => {
        normal: FONT_PATH.join("ipaexg.ttf").to_s,
        bold: FONT_PATH.join("ipaexg.ttf").to_s
      }
    )
    pdf.font "IPA"
  end

  # ==================== 表紙 ====================
  def render_cover(pdf)
    # ヘッダー行（ページ番号 + 日付 + 会社情報）
    render_cover_header(pdf)

    pdf.move_down 15

    # タイトル
    pdf.fill_color ACCENT_COLOR
    pdf.text "御 見 積 書", size: 24, style: :bold, align: :center, character_spacing: 8
    pdf.fill_color "000000"

    pdf.move_down 5
    center = PAGE_WIDTH / 2
    pdf.stroke_color PRIMARY_COLOR
    pdf.line_width = 3
    pdf.stroke_horizontal_line center - 100, center + 100
    pdf.stroke_color LINE_COLOR
    pdf.line_width = 0.5

    pdf.move_down 20

    # 左側：宛先 + 工事情報、右側：金額ボックス
    top_y = pdf.cursor

    # 左側
    pdf.bounding_box([0, top_y], width: 380) do
      render_recipient(pdf)
      pdf.move_down 15
      render_project_info(pdf)
    end

    # 右側：金額ボックス
    pdf.bounding_box([400, top_y], width: 380) do
      render_amount_box(pdf)
    end

    # 挨拶文
    pdf.move_cursor_to top_y - 190
    render_greeting(pdf)

    # 明細テーブル
    pdf.move_down 12
    render_cover_items_table(pdf)
  end

  def render_cover_header(pdf)
    # 右上：ページ番号と日付のみ
    pdf.bounding_box([PAGE_WIDTH - 200, pdf.cursor], width: 200) do
      pdf.text "#{1} / #{total_pages} ページ", size: 9, align: :right, color: "666666"
      pdf.move_down 3
      pdf.text format_date_jp(@estimate.estimate_date), size: 12, align: :right
    end

    pdf.stroke_color LINE_COLOR
    pdf.line_width = 0.5
  end

  def render_recipient(pdf)
    pdf.fill_color ACCENT_COLOR
    recipient_text = @estimate.recipient.present? ? @estimate.recipient : "（宛先未設定）"
    pdf.text "#{recipient_text}　御中", size: 16, style: :bold
    pdf.fill_color "000000"

    pdf.move_down 3
    pdf.stroke_color PRIMARY_COLOR
    pdf.line_width = 2
    pdf.stroke_horizontal_line 0, 320
    pdf.stroke_color LINE_COLOR
    pdf.line_width = 0.5
  end

  def render_project_info(pdf)
    info_data = [
      ["工 事 名", @estimate.subject],
      ["工事場所", @estimate.location],
      ["工　　期", period_text],
      ["有効期限", @estimate.validity_period || "見積日より3ヵ月"],
      ["支払条件", @estimate.payment_terms],
      ["産業廃棄物", @estimate.waste_disposal_note || "着工前に産廃契約をお願いします"],
      ["特記事項", @estimate.special_note || "別紙、工事見積確認書及び見積条件書による"],
      ["担 当 者", @estimate.person_in_charge]
    ]

    info_data.each do |label, value|
      pdf.fill_color SECONDARY_COLOR
      pdf.text_box "【#{label}】", at: [0, pdf.cursor], width: 80, size: 9
      pdf.fill_color "000000"
      display_value = value.present? ? value.to_s : "-"
      pdf.text_box display_value, at: [85, pdf.cursor], width: 290, size: 9
      pdf.move_down 14
    end
  end

  def period_text
    start_date = format_date_short(@estimate.period_start)
    end_date = format_date_short(@estimate.period_end)
    if start_date.present? && end_date.present?
      "自 #{start_date}　至 #{end_date}"
    else
      "-"
    end
  end

  def render_amount_box(pdf)
    box_width = 375

    pdf.move_down 25

    # 会社名（横並び・黒文字・大きく）
    pdf.fill_color "000000"
    pdf.text "株式会社 サンユウテック", size: 20, style: :bold, align: :center
    pdf.fill_color "000000"

    pdf.move_down 10

    # 住所・連絡先（大きく）
    pdf.fill_color "333333"
    pdf.text "〒816-0912 福岡県大野城市御笠川6丁目2-5", size: 11, align: :center
    pdf.text "TEL: 092-555-9211  FAX: 092-555-9217", size: 11, align: :center
    pdf.fill_color "000000"

    pdf.move_down 18

    # 金額ボックス
    amount_box_height = 95

    pdf.fill_color LIGHT_BG
    pdf.fill_rounded_rectangle [0, pdf.cursor], box_width, amount_box_height, 5
    pdf.fill_color "000000"

    pdf.stroke_color PRIMARY_COLOR
    pdf.line_width = 2
    pdf.stroke_rounded_rectangle [0, pdf.cursor], box_width, amount_box_height, 5

    inner_width = box_width - 30  # 左右15pxずつのパディング

    pdf.move_down 12
    pdf.indent(15) do
      # 小計・消費税（横並び）
      pdf.text_box "小計　#{format_currency(@estimate.subtotal)}", at: [0, pdf.cursor], width: 160, size: 10
      pdf.text_box "消費税　#{format_currency(@estimate.tax_amount)}", at: [165, pdf.cursor], width: 175, size: 10, align: :right
      pdf.move_down 18

      # 区切り線
      pdf.stroke_color PRIMARY_COLOR
      pdf.line_width = 1
      pdf.stroke_horizontal_line 0, inner_width
      pdf.move_down 10

      # 合計金額ラベル
      pdf.fill_color PRIMARY_COLOR
      pdf.text_box "御 見 積 金 額（税込）", at: [0, pdf.cursor], width: inner_width, size: 11, style: :bold
      pdf.fill_color "000000"
      pdf.move_down 18

      # 合計金額（右寄せ、ボックス内に収める）
      pdf.fill_color ACCENT_COLOR
      pdf.text_box format_currency(@estimate.total_amount), at: [0, pdf.cursor], width: inner_width, size: 22, style: :bold, align: :right
      pdf.fill_color "000000"
    end

    pdf.stroke_color LINE_COLOR
    pdf.line_width = 0.5
  end

  def render_amount_line(pdf, label, amount, size)
    pdf.text_box label, at: [pdf.bounds.left, pdf.cursor], width: 140, size: size
    pdf.text_box format_currency(amount), at: [pdf.bounds.left + 150, pdf.cursor], width: 180, size: size, align: :right
    pdf.move_down size + 4
  end

  def render_greeting(pdf)
    pdf.fill_color "444444"
    pdf.text "毎度、格別の御引立を賜り有難うございます。", size: 9
    pdf.text "御依頼を戴きました本件に付き、誠心誠意検討を加え御見積りいたしましたので", size: 9
    pdf.text "是非御下命戴けます様、お願い申し上げます。", size: 9
    pdf.fill_color "000000"
  end

  def render_cover_items_table(pdf)
    cats = estimate_categories

    header = ["No.", "名　　称", "仕様・規格・寸法", "数量", "単位", "単　価", "金　　額", "備　考"]
    data = [header]

    # 工種ごとに一式で表示（小計＝直接工事費+諸経費+法定福利費）
    if cats.any?
      cats.each_with_index do |category, idx|
        data << [
          (idx + 1).to_s,
          "#{category.name}",
          "",
          "1.0",
          "式",
          "",
          format_num(category.subtotal),
          ""
        ]
      end
    else
      # カテゴリがない場合は項目を直接表示
      @estimate.estimate_items.each_with_index do |item, idx|
        data << [
          (idx + 1).to_s,
          item.name || "",
          item.specification || "",
          format_qty(item.quantity),
          item.unit || "",
          format_num(item.unit_price),
          format_num(item.amount),
          item.note || ""
        ]
      end
    end

    items_count = cats.any? ? cats.count : @estimate.estimate_items.count

    # 空行（最低2行確保）
    empty_rows = [2 - items_count, 0].max
    empty_rows.times { data << ["", "", "", "", "", "", "", ""] }

    # 経費項目（合計のみ表示）
    data << cost_row("直接工事費 計", nil, @estimate.direct_cost)
    data << cost_row("諸経費 計", nil, @estimate.overhead_cost)
    data << cost_row("法定福利費 計", nil, @estimate.welfare_cost)

    if @estimate.adjustment.present? && @estimate.adjustment != 0
      data << ["", "端数調整", "", "", "", "", format_num(@estimate.adjustment), ""]
    end

    # 合計行
    data << ["", "合　計　（税抜）", "", "", "", "", format_num(@estimate.subtotal), ""]

    col_widths = [30, 140, 190, 45, 35, 70, 95, 115]

    pdf.table(data, column_widths: col_widths, position: :center, cell_style: { size: 9, padding: [3, 4], height: ROW_HEIGHT }) do |t|
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

      # 経費行の背景色
      cost_start = 1 + items_count + empty_rows
      (cost_start...(data.length - 1)).each do |i|
        t.row(i).background_color = LIGHT_BG
      end
    end
  end

  def cost_row(name, rate, amount)
    spec = rate.present? ? rate : ""
    ["", name, spec, "1.0", "式", "", format_num(amount), ""]
  end

  # ==================== 内訳明細書（工種別ページ） ====================
  def render_breakdown_pages(pdf)
    cats = estimate_categories.presence || [nil]  # カテゴリがない場合はnilで1回ループ
    total_categories = cats.count

    cats.each_with_index do |category, idx|
      pdf.start_new_page

      # ページ番号計算
      current_page = breakdown_page_number + idx

      # 複数工種の場合は「1/3」形式で表示
      if total_categories > 1
        page_label = "#{idx + 1}/#{total_categories}"
        render_page_header_with_subpage(pdf, "内 訳 明 細 書", current_page, page_label)
      else
        render_page_header(pdf, "内 訳 明 細 書", current_page)
      end

      if category
        # 工種名ヘッダー
        render_category_header(pdf, category, idx + 1)

        # 明細テーブル
        render_category_breakdown_table(pdf, category)

        # 工種別経費
        render_category_costs(pdf, category)
      else
        # カテゴリなしの場合（後方互換）
        items = @estimate.estimate_items.order(:sort_order)
        render_legacy_breakdown_table(pdf, items)
      end

    end
  end

  def render_category_header(pdf, category, category_num)
    pdf.fill_color SECONDARY_COLOR
    pdf.text "【#{category_num}. #{category.name} 一式】", size: 14, style: :bold
    pdf.fill_color "000000"
    pdf.move_down 10
  end

  def render_category_breakdown_table(pdf, category)
    items = category.estimate_items.order(:sort_order)

    header = ["名　　称", "規　　　　格", "数　量", "単　位", "単　　価", "金　　額", "備　　考"]
    data = [header]

    items.each do |item|
      data << [
        item.name || "",
        item.specification || "",
        format_qty(item.quantity),
        item.unit || "",
        format_num(item.unit_price),
        format_num(item.amount),
        item.note || ""
      ]
    end

    # 空行（最低3行）
    empty_rows = [3 - items.count, 0].max
    empty_rows.times { data << ["", "", "", "", "", "", ""] }

    # 直接工事費小計
    data << ["直接工事費　小計", "", "", "式", "", format_num(category.direct_cost), ""]

    col_widths = [160, 180, 50, 45, 85, 100, 100]

    pdf.table(data, column_widths: col_widths, position: :center, cell_style: { size: 9, padding: [3, 4], height: ROW_HEIGHT }) do |t|
      t.row(0).background_color = PRIMARY_COLOR
      t.row(0).text_color = "FFFFFF"
      t.row(0).font_style = :bold
      t.row(0).align = :center
      t.row(0).height = HEADER_HEIGHT

      t.columns(2..5).align = :right
      t.cells.borders = [:top, :bottom, :left, :right]
      t.cells.border_width = 0.5
      t.cells.border_color = BORDER_COLOR

      # 小計行のスタイル
      t.row(-1).background_color = LIGHT_BG
      t.row(-1).font_style = :bold
    end
  end

  def render_category_costs(pdf, category)
    return if category.overhead_rate.to_f.zero? && category.welfare_rate.to_f.zero?

    pdf.move_down 8

    cost_data = []

    if category.overhead_rate.to_f > 0
      cost_data << ["諸経費", "#{category.overhead_rate}%", "1.0", "式", "", format_num(category.overhead_cost), ""]
    end

    if category.welfare_rate.to_f > 0
      cost_data << ["法定福利費", "#{category.welfare_rate}%", "1.0", "式", "", format_num(category.welfare_cost), ""]
    end

    cost_data << ["【工種小計】", "", "", "", "", format_num(category.subtotal), ""]

    col_widths = [160, 180, 50, 45, 85, 100, 100]

    pdf.table(cost_data, column_widths: col_widths, position: :center, cell_style: { size: 9, padding: [3, 4], height: ROW_HEIGHT }) do |t|
      t.columns(2..5).align = :right
      t.cells.borders = [:top, :bottom, :left, :right]
      t.cells.border_width = 0.5
      t.cells.border_color = BORDER_COLOR

      t.row(-1).background_color = CATEGORY_BG
      t.row(-1).font_style = :bold
    end
  end

  def render_legacy_breakdown_table(pdf, items)
    header = ["名　　称", "規　　　　格", "数　量", "単　位", "単　　価", "金　　額", "備　　考"]
    data = [header]

    items.each do |item|
      data << [
        item.name || "",
        item.specification || "",
        format_qty(item.quantity),
        item.unit || "",
        format_num(item.unit_price),
        format_num(item.amount),
        item.note || ""
      ]
    end

    empty_rows = [3 - items.count, 0].max
    empty_rows.times { data << ["", "", "", "", "", "", ""] }

    data << ["直接工事費　小計", "", "", "式", "", format_num(@estimate.direct_cost), ""]

    col_widths = [160, 180, 50, 45, 85, 100, 100]

    pdf.table(data, column_widths: col_widths, position: :center, cell_style: { size: 9, padding: [3, 4], height: ROW_HEIGHT }) do |t|
      t.row(0).background_color = PRIMARY_COLOR
      t.row(0).text_color = "FFFFFF"
      t.row(0).font_style = :bold
      t.row(0).align = :center
      t.row(0).height = HEADER_HEIGHT

      t.columns(2..5).align = :right
      t.cells.borders = [:top, :bottom, :left, :right]
      t.cells.border_width = 0.5
      t.cells.border_color = BORDER_COLOR

      t.row(-1).background_color = LIGHT_BG
      t.row(-1).font_style = :bold
    end
  end

  # EstimateCategoryを取得（メモ化）
  def estimate_categories
    @estimate_categories ||= @estimate.estimate_categories.includes(:estimate_items).order(:sort_order)
  end

  # 後方互換性のためのメソッド（工種がない場合のフォールバック）
  def grouped_categories
    @grouped_categories ||= begin
      if estimate_categories.any?
        estimate_categories.map { |cat| [cat.name, cat.estimate_items.to_a] }.to_h
      else
        items = @estimate.estimate_items.order(:sort_order)
        return { "工事" => items.to_a } if items.empty?
        { "工事" => items.to_a }
      end
    end
  end

  # ==================== 工事確認書 ====================
  def render_confirmation_page(pdf)
    render_confirmation_tables(pdf)
  end

  def render_confirmation_tables(pdf)
    confirmations = @estimate.estimate_confirmations.order(:sort_order)

    header = ["項　目", "内　　容", "当社", "御社", "備　　考"]
    all_rows = []

    current_category = nil
    confirmations.each do |conf|
      if conf.item_category != current_category
        current_category = conf.item_category
        all_rows << { type: :category, content: current_category }
      end

      responsibility_ours = conf.responsibility == "ours" ? "○" : ""
      responsibility_theirs = conf.responsibility == "theirs" ? "○" : ""

      all_rows << {
        type: :item,
        content: [
          "",
          conf.item_name || "",
          responsibility_ours,
          responsibility_theirs,
          conf.note || ""
        ]
      }
    end

    # 高さベースで1ページあたりの最大行数を計算
    confirmation_row_height = 16
    confirmation_header_height = 20
    max_rows = calculate_max_rows(confirmation_row_height, confirmation_header_height)

    # ページごとに分割
    pages = all_rows.each_slice(max_rows).to_a
    total_confirmation_pages = pages.count

    pages.each_with_index do |page_rows, page_idx|
      # 2ページ目以降は新しいページを開始
      if page_idx > 0
        pdf.start_new_page
      end

      # 複数ページの場合は「1/2」形式、1ページのみの場合は通常表記
      if total_confirmation_pages > 1
        page_label = "#{page_idx + 1}/#{total_confirmation_pages}"
        render_page_header_with_subpage(pdf, "工 事 確 認 書", confirmation_page_number + page_idx, page_label)
      else
        render_page_header(pdf, "工 事 確 認 書", confirmation_page_number)
      end

      # テーブルデータを構築
      data = [header]
      page_rows.each do |row|
        if row[:type] == :category
          data << [{ content: row[:content], colspan: 5 }]
        else
          data << row[:content]
        end
      end

      render_single_confirmation_table(pdf, data)
    end

    # 注釈（最後のページのみ）
    pdf.move_down 15
    pdf.fill_color "666666"
    pdf.text "※ 当社欄に○印のある項目は見積に含んでおります。", size: 9
    pdf.text "※ 御社欄に○印のある項目は見積に含んでおりません。御社にてご手配ください。", size: 9
    pdf.fill_color "000000"
  end

  def render_single_confirmation_table(pdf, data)
    col_widths = [100, 260, 45, 45, 270]
    confirmation_row_height = 16

    pdf.table(data, column_widths: col_widths, position: :center, cell_style: { size: 8, padding: [2, 4], height: confirmation_row_height }) do |t|
      t.row(0).background_color = PRIMARY_COLOR
      t.row(0).text_color = "FFFFFF"
      t.row(0).font_style = :bold
      t.row(0).align = :center
      t.row(0).height = 20

      t.columns(2..3).align = :center
      t.cells.borders = [:top, :bottom, :left, :right]
      t.cells.border_width = 0.5
      t.cells.border_color = BORDER_COLOR

      # カテゴリ行のスタイル
      data.each_with_index do |row, idx|
        if row.is_a?(Array) && row.length == 1 && row[0].is_a?(Hash)
          t.row(idx).background_color = CATEGORY_BG
          t.row(idx).font_style = :bold
        end
      end
    end
  end

  # ==================== 施工条件書 ====================
  def render_conditions_page(pdf)
    render_page_header(pdf, "施 工 条 件 書", conditions_page_number)
    render_conditions_table(pdf)
  end

  def render_conditions_table(pdf)
    conditions = parse_conditions(@estimate.conditions.to_s)
    return if conditions.empty?

    # ヘッダー
    data = [["No.", "施　工　条　件　内　容"]]

    # 条件行
    conditions.each_with_index do |line, idx|
      data << [(idx + 1).to_s, line]
    end

    # 空行追加（最低12行確保）
    empty_rows = [12 - conditions.count, 0].max
    empty_rows.times { |i| data << ["", ""] }

    col_widths = [40, 740]

    pdf.table(data, column_widths: col_widths, position: :center, cell_style: { size: 10, padding: [4, 6], height: ROW_HEIGHT }) do |t|
      t.row(0).background_color = PRIMARY_COLOR
      t.row(0).text_color = "FFFFFF"
      t.row(0).font_style = :bold
      t.row(0).align = :center
      t.row(0).height = HEADER_HEIGHT

      t.columns(0).align = :center
      t.cells.borders = [:top, :bottom, :left, :right]
      t.cells.border_width = 0.5
      t.cells.border_color = BORDER_COLOR
    end
  end

  def parse_conditions(text)
    lines = text.split("\n").map(&:strip).reject(&:blank?)

    # 番号を除去して内容だけ取得
    lines.map do |line|
      # 「1. 」「1．」「1　」「1 」などの番号パターンを除去
      line.sub(/^\d+[\.\s　．]+/, "")
    end
  end

  # ==================== 共通メソッド ====================
  def render_page_header(pdf, title, page_num)
    pdf.text "#{page_num} / #{total_pages} ページ", size: 9, align: :right, color: "666666"
    pdf.move_down 12

    pdf.fill_color ACCENT_COLOR
    pdf.text title, size: 18, align: :center, style: :bold, character_spacing: 6
    pdf.fill_color "000000"

    pdf.move_down 5
    render_title_underline(pdf, title)
    pdf.move_down 20
  end

  # 複数ページに跨る場合のヘッダー（タイトル横にサブページ番号）
  def render_page_header_with_subpage(pdf, title, page_num, subpage_label)
    pdf.text "#{page_num} / #{total_pages} ページ", size: 9, align: :right, color: "666666"
    pdf.move_down 12

    # タイトルとサブページ番号を横並びで表示
    pdf.fill_color ACCENT_COLOR
    pdf.text "#{title}　#{subpage_label}", size: 18, align: :center, style: :bold, character_spacing: 6
    pdf.fill_color "000000"

    pdf.move_down 5
    render_title_underline(pdf, "#{title}　#{subpage_label}")
    pdf.move_down 20
  end

  def render_title_underline(pdf, title)
    # タイトルの文字数に応じて罫線の長さを調整（文字サイズ18pt + 文字間隔6pt）
    title_chars = title.gsub(/\s/, "").length  # スペースを除いた文字数
    line_half_width = (title_chars * 24) / 2 + 20  # 文字幅 + 余白

    center = PAGE_WIDTH / 2
    pdf.stroke_color PRIMARY_COLOR
    pdf.line_width = 2
    pdf.stroke_horizontal_line center - line_half_width, center + line_half_width
    pdf.stroke_color LINE_COLOR
    pdf.line_width = 0.5
  end

  # 高さベースで1ページあたりの最大行数を計算
  def calculate_max_rows(row_height, table_header_height)
    available_height = AVAILABLE_TABLE_HEIGHT - table_header_height
    (available_height / row_height).floor
  end

  def total_pages
    pages = 1  # 表紙
    pages += breakdown_pages_count  # 内訳明細書（工種数分）
    pages += confirmation_pages_count if @estimate.estimate_confirmations.any?
    pages += 1 if @estimate.conditions.present?
    pages
  end

  def breakdown_pages_count
    estimate_categories.any? ? estimate_categories.count : 1
  end

  def confirmation_pages_count
    return 0 unless @estimate.estimate_confirmations.any?

    # カテゴリ数 + 項目数を計算
    confirmations = @estimate.estimate_confirmations.order(:sort_order)
    categories = confirmations.map(&:item_category).uniq.count
    total_rows = categories + confirmations.count

    # 高さベースで最大行数を計算
    confirmation_row_height = 16
    confirmation_header_height = 20
    max_rows = calculate_max_rows(confirmation_row_height, confirmation_header_height)

    (total_rows.to_f / max_rows).ceil
  end

  def breakdown_page_number
    2
  end

  def confirmation_page_number
    2 + breakdown_pages_count
  end

  def conditions_page_number
    pages = 2 + breakdown_pages_count
    pages += confirmation_pages_count if @estimate.estimate_confirmations.any?
    pages
  end

  def add_footer(pdf)
    pdf.repeat(:all) do
      pdf.bounding_box([0, 35], width: PAGE_WIDTH, height: 18) do
        pdf.stroke_color "DDDDDD"
        pdf.stroke_horizontal_line 0, PAGE_WIDTH
        pdf.move_down 4
        pdf.fill_color "888888"
        pdf.text "株式会社 サンユウテック", size: 8, align: :right
        pdf.fill_color "000000"
      end
    end
  end

  def format_currency(amount)
    return "-" if amount.nil?
    "¥#{number_with_delimiter(amount.to_i)}"
  end

  def format_num(num)
    return "" if num.nil? || num == 0
    number_with_delimiter(num.to_i)
  end

  def format_qty(num)
    return "" if num.nil?
    num.to_f == num.to_i ? num.to_i.to_s : format("%.1f", num)
  end

  def format_date_jp(date)
    return "" if date.nil?
    date.strftime("%Y年%m月%d日")
  end

  def format_date_short(date)
    return "" if date.nil?
    date.strftime("%Y/%m/%d")
  end
end
