# frozen_string_literal: true

# 3ヶ月分のテストデータ作成
puts "=== テストデータ作成開始 ==="

# admin@sanyu.example.com のテナントを使用（Tenant ID 2）
admin_user = Employee.find_by(email: "admin@sanyu.example.com")
tenant = admin_user&.tenant || Tenant.find_by(id: 2) || Tenant.first
unless tenant
  puts "テナントがありません。先にdb:seedを実行してください。"
  exit
end
puts "使用テナント: #{tenant.name} (ID: #{tenant.id})"

Current.tenant_id = tenant.id

# 顧客マスタ
clients = [
  { code: "C001", name: "山田建設株式会社", address: "東京都新宿区西新宿1-1-1" },
  { code: "C002", name: "鈴木工務店", address: "神奈川県横浜市中区本町2-2-2" },
  { code: "C003", name: "田中不動産", address: "千葉県千葉市中央区中央3-3-3" },
  { code: "C004", name: "佐藤ハウジング", address: "埼玉県さいたま市大宮区桜木町4-4-4" },
  { code: "C005", name: "株式会社高橋組", address: "東京都渋谷区道玄坂5-5-5" },
  { code: "C006", name: "伊藤建築事務所", address: "神奈川県川崎市川崎区駅前本町6-6-6" },
  { code: "C007", name: "渡辺土木", address: "東京都品川区大崎7-7-7" },
  { code: "C008", name: "中村リフォーム", address: "千葉県船橋市本町8-8-8" }
].map do |attrs|
  Client.find_or_create_by!(code: attrs[:code]) do |c|
    c.name = attrs[:name]
    c.address = attrs[:address]
  end
end
puts "顧客: #{clients.size}件"

# 協力会社マスタ
partners = [
  { code: "P001", name: "協力電気工業", has_temporary_employees: true },
  { code: "P002", name: "配管サービス", has_temporary_employees: true },
  { code: "P003", name: "足場レンタル", has_temporary_employees: false },
  { code: "P004", name: "塗装プロ", has_temporary_employees: false }
].map do |attrs|
  Partner.find_or_create_by!(code: attrs[:code]) do |p|
    p.name = attrs[:name]
    p.has_temporary_employees = attrs[:has_temporary_employees]
  end
end
puts "協力会社: #{partners.size}件"

# 社員取得
admin = Employee.find_by(role: "admin") || Employee.first
sales = Employee.where(role: "sales").first || admin
engineering = Employee.where(role: "engineering").first || admin
construction = Employee.where(role: "construction").first || admin
workers = Employee.where(role: %w[construction worker]).to_a
workers = [admin] if workers.empty?

puts "社員: admin=#{admin&.name}, sales=#{sales&.name}, construction=#{construction&.name}"

# ========================================
# 案件データ（様々なステータス）
# ========================================
projects_data = [
  # 完了案件（過去）
  {
    code: "PJ-2025-001", name: "新宿オフィスビル改修工事",
    client: clients[0], status: "paid",
    estimated_amount: 15_000_000, order_amount: 14_500_000, budget_amount: 12_000_000,
    scheduled_start: 3.months.ago, scheduled_end: 1.month.ago,
    actual_start: 3.months.ago, actual_end: 5.weeks.ago,
    four_point: true, pre_gate: true
  },
  {
    code: "PJ-2025-002", name: "横浜マンション外壁補修",
    client: clients[1], status: "invoiced",
    estimated_amount: 8_000_000, order_amount: 7_800_000, budget_amount: 6_500_000,
    scheduled_start: 2.months.ago, scheduled_end: 3.weeks.ago,
    actual_start: 2.months.ago, actual_end: 2.weeks.ago,
    four_point: true, pre_gate: true
  },
  {
    code: "PJ-2025-003", name: "千葉商業施設駐車場整備",
    client: clients[2], status: "completed",
    estimated_amount: 5_500_000, order_amount: 5_200_000, budget_amount: 4_300_000,
    scheduled_start: 6.weeks.ago, scheduled_end: 1.week.ago,
    actual_start: 6.weeks.ago, actual_end: 4.days.ago,
    four_point: true, pre_gate: true
  },
  # 進行中案件
  {
    code: "PJ-2025-004", name: "大宮駅前ビル内装工事",
    client: clients[3], status: "in_progress",
    estimated_amount: 12_000_000, order_amount: 11_500_000, budget_amount: 9_500_000,
    scheduled_start: 1.month.ago, scheduled_end: 2.weeks.from_now,
    actual_start: 1.month.ago, actual_end: nil,
    four_point: true, pre_gate: true
  },
  {
    code: "PJ-2025-005", name: "渋谷店舗リニューアル",
    client: clients[4], status: "in_progress",
    estimated_amount: 6_000_000, order_amount: 5_800_000, budget_amount: 4_800_000,
    scheduled_start: 2.weeks.ago, scheduled_end: 3.weeks.from_now,
    actual_start: 2.weeks.ago, actual_end: nil,
    four_point: true, pre_gate: true
  },
  {
    code: "PJ-2025-006", name: "川崎倉庫屋根補修",
    client: clients[5], status: "in_progress",
    estimated_amount: 3_500_000, order_amount: 3_300_000, budget_amount: 2_800_000,
    scheduled_start: 1.week.ago, scheduled_end: 1.month.from_now,
    actual_start: 1.week.ago, actual_end: nil,
    four_point: true, pre_gate: true
  },
  # 着工準備中
  {
    code: "PJ-2025-007", name: "品川オフィス電気設備更新",
    client: clients[6], status: "preparing",
    estimated_amount: 4_200_000, order_amount: 4_000_000, budget_amount: 3_400_000,
    scheduled_start: 1.week.from_now, scheduled_end: 2.months.from_now,
    actual_start: nil, actual_end: nil,
    four_point: true, pre_gate: false
  },
  # 受注済み（4点完了、着工前ゲート未完了）
  {
    code: "PJ-2025-008", name: "船橋住宅リフォーム",
    client: clients[7], status: "ordered",
    estimated_amount: 2_800_000, order_amount: 2_600_000, budget_amount: nil,
    scheduled_start: 2.weeks.from_now, scheduled_end: 2.months.from_now,
    actual_start: nil, actual_end: nil,
    four_point: true, pre_gate: false
  },
  # 見積中（4点未完了）
  {
    code: "PJ-2025-009", name: "新橋ビル空調工事",
    client: clients[0], status: "estimating",
    estimated_amount: 9_000_000, order_amount: nil, budget_amount: nil,
    scheduled_start: nil, scheduled_end: nil,
    actual_start: nil, actual_end: nil,
    four_point: false, pre_gate: false
  },
  {
    code: "PJ-2025-010", name: "池袋商業ビル防水工事",
    client: clients[1], status: "estimating",
    estimated_amount: 7_500_000, order_amount: nil, budget_amount: nil,
    scheduled_start: nil, scheduled_end: nil,
    actual_start: nil, actual_end: nil,
    four_point: false, pre_gate: false
  },
  # 下書き
  {
    code: "PJ-2025-011", name: "目黒マンション大規模修繕（仮）",
    client: clients[2], status: "draft",
    estimated_amount: nil, order_amount: nil, budget_amount: nil,
    scheduled_start: nil, scheduled_end: nil,
    actual_start: nil, actual_end: nil,
    four_point: false, pre_gate: false
  },
  # その他（常用）案件
  {
    code: "PJ-2025-M01", name: "常用工事A（山田建設向け）",
    client: clients[0], status: "in_progress", project_type: "misc",
    estimated_amount: nil, order_amount: nil, budget_amount: nil,
    scheduled_start: 1.month.ago, scheduled_end: 1.month.from_now,
    actual_start: 1.month.ago, actual_end: nil,
    four_point: true, pre_gate: true
  }
]

created_projects = []
projects_data.each do |data|
  project = Project.find_or_initialize_by(code: data[:code])
  project.assign_attributes(
    name: data[:name],
    client: data[:client],
    status: data[:status],
    project_type: data[:project_type] || "regular",
    estimated_amount: data[:estimated_amount],
    order_amount: data[:order_amount],
    budget_amount: data[:budget_amount],
    scheduled_start_date: data[:scheduled_start]&.to_date,
    scheduled_end_date: data[:scheduled_end]&.to_date,
    actual_start_date: data[:actual_start]&.to_date,
    actual_end_date: data[:actual_end]&.to_date,
    sales_user_id: sales.id,
    engineering_user_id: engineering.id,
    construction_user_id: construction.id,
    site_address: "東京都#{%w[新宿区 渋谷区 品川区 港区].sample}#{rand(1..10)}-#{rand(1..20)}-#{rand(1..30)}"
  )

  if data[:four_point]
    project.has_contract = true
    project.has_order = true
    project.has_payment_terms = true
    project.has_customer_approval = true
    project.four_point_completed_at = 2.months.ago
  end

  if data[:pre_gate]
    project.site_conditions_checked = true
    project.night_work_checked = true
    project.regulations_checked = true
    project.safety_docs_checked = true
    project.delivery_checked = true
    project.pre_construction_gate_completed_at = 6.weeks.ago
  end

  project.save!
  created_projects << project
end
puts "案件: #{created_projects.size}件"

# ========================================
# 実行予算
# ========================================
created_projects.select { |p| p.budget_amount.present? }.each do |project|
  budget = Budget.find_or_initialize_by(project: project)
  budget.assign_attributes(
    material_cost: (project.budget_amount * 0.35).round,
    outsourcing_cost: (project.budget_amount * 0.25).round,
    labor_cost: (project.budget_amount * 0.30).round,
    expense_cost: (project.budget_amount * 0.10).round,
    status: project.status.in?(%w[in_progress completed invoiced paid]) ? "confirmed" : "draft"
  )
  budget.save!
end
puts "実行予算: #{Budget.count}件"

# ========================================
# 日報データ（過去3ヶ月分）
# ========================================
daily_report_count = 0
weathers = DailyReport::WEATHERS

# 進行中・完了案件に日報を作成
created_projects.select { |p| p.actual_start_date.present? }.each do |project|
  start_date = project.actual_start_date
  end_date = project.actual_end_date || Date.current

  # 営業日のみ（土日除く）
  (start_date..end_date).each do |date|
    next if date.saturday? || date.sunday?
    next if rand < 0.1 # 10%は日報なし（リアリティ）

    report = DailyReport.find_or_initialize_by(project: project, report_date: date)
    next if report.persisted?

    report.assign_attributes(
      foreman: workers.sample,
      weather: weathers.sample,
      work_content: [
        "基礎工事実施",
        "内装下地作業",
        "配管設置作業",
        "電気配線工事",
        "塗装作業",
        "クリーニング作業",
        "検査対応",
        "資材搬入",
        "養生作業"
      ].sample,
      notes: rand < 0.3 ? "特記事項なし" : nil,
      labor_cost: rand(50_000..150_000),
      material_cost: rand(10_000..80_000),
      outsourcing_cost: rand < 0.3 ? rand(30_000..100_000) : 0,
      transportation_cost: rand(5_000..20_000),
      status: date < Date.current ? "confirmed" : "draft",
      confirmed_at: date < Date.current ? date + 1.day : nil
    )

    if report.save
      daily_report_count += 1

      # 出面データ
      workers.sample(rand(2..5)).each do |worker|
        Attendance.find_or_create_by!(daily_report: report, employee: worker) do |a|
          a.attendance_type = %w[full full full half absent].sample
          a.hours_worked = a.attendance_type == "full" ? 8.0 : (a.attendance_type == "half" ? 4.0 : 0)
        end
      end
    end
  end
end

# 常用日報（外部現場）
external_sites = ["○○建設 新宿現場", "△△工務店 横浜作業所", "□□不動産 品川ビル"]
(90.days.ago.to_date..Date.current).each do |date|
  next if date.saturday? || date.sunday?
  next if rand < 0.7 # 30%の確率で常用日報

  report = DailyReport.new(
    is_external: true,
    external_site_name: external_sites.sample,
    report_date: date,
    foreman: workers.sample,
    weather: weathers.sample,
    work_content: "常用作業（応援）",
    labor_cost: rand(80_000..200_000),
    status: date < Date.current ? "confirmed" : "draft",
    confirmed_at: date < Date.current ? date + 1.day : nil
  )

  if report.save
    daily_report_count += 1

    # 出面（作業員の出勤記録）
    workers.sample(rand(1..3)).each do |worker|
      Attendance.find_or_create_by!(
        daily_report: report,
        employee: worker
      ) do |a|
        a.attendance_type = "full"
        a.hours_worked = 8.0
      end
    end
  end
end
puts "日報: #{daily_report_count}件"

# ========================================
# 請求書データ
# ========================================
invoice_count = 0
created_projects.select { |p| p.status.in?(%w[completed invoiced paid]) }.each do |project|
  invoice = Invoice.find_or_initialize_by(project: project)
  next if invoice.persisted?

  amount = project.order_amount || project.estimated_amount || 1_000_000
  tax = (amount * 0.1).round

  invoice.assign_attributes(
    invoice_number: "INV-#{project.code.gsub('PJ-', '')}",
    amount: amount,
    tax_amount: tax,
    total_amount: amount + tax,
    issued_date: project.actual_end_date || 1.week.ago,
    due_date: (project.actual_end_date || 1.week.ago) + 30.days,
    status: project.status == "paid" ? "paid" : (project.status == "invoiced" ? "issued" : "draft")
  )

  if invoice.save
    invoice_count += 1

    # 明細行
    InvoiceItem.find_or_create_by!(invoice: invoice, name: project.name) do |item|
      item.work_date = project.actual_end_date || Date.current
      item.quantity = 1
      item.unit = "式"
      item.unit_price = amount
      item.subtotal = amount
    end

    # 入金データ（完了案件）
    if project.status == "paid"
      Payment.find_or_create_by!(invoice: invoice) do |p|
        p.amount = invoice.total_amount
        p.payment_date = invoice.due_date - rand(1..10).days
        p.notes = "入金確認済"
      end
    end
  end
end
puts "請求書: #{invoice_count}件"

# ========================================
# 仮社員相殺データ
# ========================================
offset_count = 0
partners.first(2).each do |partner|
  3.times do |i|
    year_month = (Date.current - i.months).strftime("%Y-%m")
    offset = Offset.find_or_initialize_by(partner: partner, year_month: year_month)
    next if offset.persisted?

    offset.assign_attributes(
      total_salary: rand(300_000..600_000),
      social_insurance: rand(30_000..60_000),
      offset_amount: rand(100_000..300_000),
      revenue_amount: rand(200_000..500_000),
      status: i > 0 ? "confirmed" : "draft",
      confirmed_at: i > 0 ? Date.current - i.months + 15.days : nil
    )

    if offset.save
      offset_count += 1
    end
  end
end
puts "相殺データ: #{offset_count}件"

# ========================================
# 安全書類フォルダ
# ========================================
folders = [
  { name: "施工計画書", description: "各現場の施工計画書を保管" },
  { name: "安全書類（共通）", description: "全現場共通の安全書類" },
  { name: "資格証明書", description: "作業員の資格証明書コピー" }
]

folders.each do |f|
  SafetyFolder.find_or_create_by!(name: f[:name]) do |folder|
    folder.description = f[:description]
  end
end

# 案件別フォルダ
created_projects.first(5).each do |project|
  SafetyFolder.find_or_create_by!(name: "#{project.code} 安全書類", project: project) do |folder|
    folder.description = "#{project.name}の安全書類"
  end
end
puts "安全書類フォルダ: #{SafetyFolder.count}件"

puts ""
puts "=== テストデータ作成完了 ==="
puts ""
puts "【サマリー】"
puts "  顧客: #{Client.count}件"
puts "  協力会社: #{Partner.count}件"
puts "  案件: #{Project.count}件"
puts "  実行予算: #{Budget.count}件"
puts "  日報: #{DailyReport.count}件"
puts "  出面: #{Attendance.count}件"
puts "  請求書: #{Invoice.count}件"
puts "  入金: #{Payment.count}件"
puts "  相殺: #{Offset.count}件"
puts "  安全書類フォルダ: #{SafetyFolder.count}件"
puts ""
puts "【案件ステータス別】"
Project.group(:status).count.each do |status, count|
  puts "  #{status}: #{count}件"
end
