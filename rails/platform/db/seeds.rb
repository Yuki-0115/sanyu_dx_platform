# frozen_string_literal: true

puts "=== Seeding database ==="

# Create admin employee
admin = Employee.find_by(email: "admin@sanyu.example.com")
unless admin
  admin = Employee.new(
    code: "EMP001", name: "管理者",
    email: "admin@sanyu.example.com", employment_type: "regular",
    role: "admin", password: "password123", password_confirmation: "password123"
  )
  admin.save!
end

puts "Created admin: #{admin.email} (password: password123)"

# Create management employee
manager = Employee.find_by(email: "manager@sanyu.example.com")
unless manager
  manager = Employee.new(
    code: "EMP002", name: "経営担当",
    email: "manager@sanyu.example.com", employment_type: "regular",
    role: "management", password: "password123", password_confirmation: "password123"
  )
  manager.save!
end

puts "Created manager: #{manager.email} (password: password123)"

# Create construction employee
foreman = Employee.find_by(email: "foreman@sanyu.example.com")
unless foreman
  foreman = Employee.new(
    code: "EMP003", name: "職長太郎",
    email: "foreman@sanyu.example.com", employment_type: "regular",
    role: "construction", password: "password123", password_confirmation: "password123"
  )
  foreman.save!
end

puts "Created foreman: #{foreman.email} (password: password123)"

# Create sample clients
client1 = Client.find_or_create_by!(code: "CLI001") do |c|
  c.name = "株式会社テスト建設"
end

client2 = Client.find_or_create_by!(code: "CLI002") do |c|
  c.name = "サンプル工業株式会社"
end

puts "Created clients: #{client1.name}, #{client2.name}"

# Create sample project
project = Project.find_or_create_by!(code: "PJ001") do |p|
  p.name = "サンプル新築工事"
  p.client = client1
  p.sales_user = manager
  p.status = "estimating"
  p.estimated_amount = 50_000_000
  p.order_amount = 48_000_000
  p.budget_amount = 40_000_000
end

puts "Created project: #{project.name}"

# Create sample partners (協力会社)
# 仮社員を持つ協力会社（勤怠管理対象）
partner1 = Partner.find_or_create_by!(code: "PTN001") do |p|
  p.name = "協力建設株式会社"
  p.has_temporary_employees = true
end

partner2 = Partner.find_or_create_by!(code: "PTN002") do |p|
  p.name = "テスト工業"
  p.has_temporary_employees = true
end

# 外注会社（原価管理対象）
partner3 = Partner.find_or_create_by!(code: "PTN003") do |p|
  p.name = "大和電設"
  p.has_temporary_employees = false
end

partner4 = Partner.find_or_create_by!(code: "PTN004") do |p|
  p.name = "関東配管工業"
  p.has_temporary_employees = false
end

partner5 = Partner.find_or_create_by!(code: "PTN005") do |p|
  p.name = "東京塗装"
  p.has_temporary_employees = false
end

puts "Created partners: #{partner1.name}, #{partner2.name}, #{partner3.name}, #{partner4.name}, #{partner5.name}"

# 外注会社リスト（シード用）
external_partners = [partner3, partner4, partner5]

# Create sample employees (workers) - 20名程度
workers_data = [
  # 正社員 (regular) - 勤怠管理対象
  { code: "EMP004", name: "山田 太郎", employment_type: "regular", role: "construction" },
  { code: "EMP005", name: "佐藤 次郎", employment_type: "regular", role: "construction" },
  { code: "EMP006", name: "鈴木 三郎", employment_type: "regular", role: "construction" },
  { code: "EMP007", name: "田中 四郎", employment_type: "regular", role: "construction" },
  { code: "EMP008", name: "高橋 五郎", employment_type: "regular", role: "construction" },
  { code: "EMP009", name: "伊藤 六郎", employment_type: "regular", role: "engineering" },
  { code: "EMP010", name: "渡辺 七郎", employment_type: "regular", role: "sales" },
  # 仮社員 (temporary) - 勤怠管理対象（協力会社から派遣）
  { code: "EMP011", name: "小林 一夫", employment_type: "temporary", role: "worker", partner: partner1 },
  { code: "EMP012", name: "加藤 二夫", employment_type: "temporary", role: "worker", partner: partner1 },
  { code: "EMP013", name: "吉田 三夫", employment_type: "temporary", role: "worker", partner: partner1 },
  { code: "EMP014", name: "山本 四夫", employment_type: "temporary", role: "worker", partner: partner2 },
  { code: "EMP015", name: "中村 五夫", employment_type: "temporary", role: "worker", partner: partner2 },
  { code: "EMP016", name: "小川 六夫", employment_type: "temporary", role: "worker", partner: partner2 },
]

workers = []
workers_data.each do |data|
  emp = Employee.find_by(code: data[:code])
  unless emp
    emp = Employee.new(
      code: data[:code],
      name: data[:name],
      employment_type: data[:employment_type],
      role: data[:role],
      partner: data[:partner],
      email: "#{data[:code].downcase}@sanyu.example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    emp.save!
  end
  workers << emp
end

puts "Created #{workers.size} workers"

# Create additional projects for variety
project2 = Project.find_or_create_by!(code: "PJ002") do |p|
  p.name = "駅前ビル改修工事"
  p.client = client2
  p.sales_user = manager
  p.status = "in_progress"
  p.estimated_amount = 30_000_000
  p.scheduled_start_date = Date.current.beginning_of_month
  p.scheduled_end_date = Date.current.end_of_month + 2.months
end

project3 = Project.find_or_create_by!(code: "PJ003") do |p|
  p.name = "マンション外壁工事"
  p.client = client1
  p.sales_user = manager
  p.status = "in_progress"
  p.estimated_amount = 15_000_000
  p.scheduled_start_date = Date.current.beginning_of_month
  p.scheduled_end_date = Date.current.end_of_month + 1.month
end

puts "Created projects: #{project2.name}, #{project3.name}"

# 勤怠管理対象の社員（正社員・仮社員のみ）
attendance_workers = [admin, manager, foreman] + workers.select { |w| w.employment_type.in?(%w[regular temporary]) }
projects = [project, project2, project3]

# 今月の日報と出勤データを作成
(Date.current.beginning_of_month..Date.current).each do |date|
  next if date.wday == 0 # 日曜は休み

  projects.each_with_index do |proj, proj_idx|
    # 各案件に対して日報を作成（職長が入力）
    daily_report = DailyReport.find_or_initialize_by(
      project: proj,
      report_date: date
    )

    if daily_report.new_record?
      daily_report.foreman = foreman
      daily_report.weather = %w[sunny cloudy rainy].sample
      daily_report.work_content = "本日の作業内容"
      daily_report.status = "confirmed"
      daily_report.save!

      # ランダムに作業員を割り当て（各案件5-8名程度）- 正社員・仮社員のみ
      assigned_workers = attendance_workers.sample(rand(5..8))
      assigned_workers.each do |worker|
        # 土曜は半日の可能性
        attendance_type = if date.wday == 6
                            %w[full half].sample
                          else
                            rand < 0.9 ? "full" : "half"
                          end

        Attendance.find_or_create_by!(
          daily_report: daily_report,
          employee: worker
        ) do |att|
          att.attendance_type = attendance_type
          att.hours_worked = attendance_type == "full" ? 8 : 4
        end
      end

      # 外注入力（OutsourcingEntry）- 日報ごとに0-2社
      rand(0..2).times do
        partner = external_partners.sample
        headcount = rand(1..5)
        attendance_type = rand < 0.85 ? "full" : "half"

        # 同じ日報・同じ協力会社の重複を避ける
        unless OutsourcingEntry.exists?(daily_report: daily_report, partner: partner)
          OutsourcingEntry.create!(
            daily_report: daily_report,
            partner: partner,
            headcount: headcount,
            attendance_type: attendance_type
          )
        end
      end
    end
  end
end

puts "Created daily reports and attendances for current month"

# === 有給休暇テストデータ ===
puts "\n=== Creating paid leave data ==="

# 正社員に入社日と基準日を設定
regular_employees = Employee.where(employment_type: "regular")

regular_employees.each_with_index do |emp, idx|
  # 入社日を1〜5年前にランダム設定
  years_ago = rand(1..5)
  hire_date = Date.current - years_ago.years - rand(0..11).months
  emp.update!(
    hire_date: hire_date,
    paid_leave_base_date: hire_date + 6.months
  )
end

puts "Updated hire dates for #{regular_employees.count} employees"

# 有給付与データ作成
regular_employees.reload.each do |emp|
  next unless emp.hire_date

  # 既存の付与データがあればスキップ
  next if emp.paid_leave_grants.any?

  service = PaidLeaveGrantService.new(emp)

  # 前年度の付与
  prev_grant_date = emp.paid_leave_base_date + 1.year
  prev_fiscal_year = prev_grant_date.month >= 4 ? prev_grant_date.year : prev_grant_date.year - 1
  used_prev = rand(3..8)
  granted_prev = 11

  prev_year_grant = emp.paid_leave_grants.create!(
    grant_type: "auto",
    grant_date: prev_grant_date,
    expiry_date: prev_grant_date + 2.years,
    fiscal_year: prev_fiscal_year,
    granted_days: granted_prev,
    used_days: used_prev,
    remaining_days: [granted_prev - used_prev, 0].max
  )

  # 今年度の付与
  current_grant_date = emp.paid_leave_base_date + 2.years
  current_fiscal_year = current_grant_date.month >= 4 ? current_grant_date.year : current_grant_date.year - 1
  granted_current = service.calculate_grant_days
  used_current = rand(0..3)

  current_grant = emp.paid_leave_grants.create!(
    grant_type: "auto",
    grant_date: current_grant_date,
    expiry_date: current_grant_date + 2.years,
    fiscal_year: current_fiscal_year,
    granted_days: granted_current,
    used_days: used_current,
    remaining_days: [granted_current - used_current, 0].max
  )
end

puts "Created paid leave grants"

# 有給申請データ作成
# 承認済み申請（過去の取得実績）- バリデーションをスキップして作成
admin_user = Employee.find_by(role: "admin")

regular_employees.each do |emp|
  grant = emp.paid_leave_grants.order(grant_date: :asc).where("remaining_days > 0").first
  next unless grant

  # 過去1-3件の承認済み申請
  rand(1..3).times do |i|
    leave_date = Date.current - rand(10..60).days
    next if emp.paid_leave_requests.exists?(leave_date: leave_date)

    leave_type = %w[full half_am half_pm].sample
    consumed = leave_type == "full" ? 1.0 : 0.5

    request = emp.paid_leave_requests.new(
      paid_leave_grant: grant,
      leave_date: leave_date,
      leave_type: leave_type,
      consumed_days: consumed,
      reason: ["私用のため", "通院のため", "家族の用事", ""].sample,
      status: "approved",
      approved_by: admin_user,
      approved_at: leave_date - 3.days
    )
    request.save!(validate: false) # 過去日付のバリデーションをスキップ
  end
end

puts "Created approved leave requests"

# 承認待ち申請（未来の申請）
pending_employees = regular_employees.sample(4)
pending_employees.each do |emp|
  leave_date = Date.current + rand(3..14).days
  next if emp.paid_leave_requests.exists?(leave_date: leave_date)

  emp.paid_leave_requests.create!(
    leave_date: leave_date,
    leave_type: %w[full half_am half_pm].sample,
    consumed_days: [1.0, 0.5].sample,
    reason: ["旅行のため", "法事のため", "引越しのため", "資格試験のため"].sample,
    status: "pending"
  )
end

puts "Created #{pending_employees.size} pending leave requests"

# 却下された申請（1件）
rejected_emp = regular_employees.sample
rejected_date = Date.current + 5.days
unless rejected_emp.paid_leave_requests.exists?(leave_date: rejected_date)
  rejected_emp.paid_leave_requests.create!(
    leave_date: rejected_date,
    leave_type: "full",
    consumed_days: 1.0,
    reason: "私用のため",
    status: "rejected",
    approved_by: Employee.find_by(role: "admin"),
    approved_at: Date.current - 1.day,
    rejection_reason: "繁忙期のため、別日程への変更をお願いします"
  )
end

puts "Created rejected leave request"

# 5日未達者を作るため、一部社員の取得日数を調整
at_risk_employees = regular_employees.sample(2)
at_risk_employees.each do |emp|
  # 今年度の申請を減らす
  emp.paid_leave_requests.where(status: "approved").limit(2).destroy_all
end

puts "Adjusted at-risk employees: #{at_risk_employees.map(&:name).join(', ')}"

puts "\n=== Seed completed ==="
puts "Login with: admin@sanyu.example.com / password123"

# ========================================
# 見積テンプレート（デフォルト）
# ========================================
puts "Creating estimate templates..."

# 条件書テンプレート
condition_templates = [
  {
    name: "舗装工事_標準",
    content: <<~TEXT.strip
      ・産業廃棄物 運搬処分は別途
      ・昼間施工 08:00～17:00
      ・舗装機械 小物機械 含む
      ・重機 労務回送 1往復 含みます
      ・路床 路盤 軟弱な場合は別途協議願います
      ・勾配1.5％以上確保願います
      ・舗装版切断 含みません
      ・安全費 ガードマンは含みません
      ・掘削残土運搬処分 含みません
    TEXT
  },
  {
    name: "地盤改良_標準",
    content: <<~TEXT.strip
      ・産業廃棄物 運搬処分は別途
      ・昼間施工 08:00～17:00
      ・地盤改良機械 含む
      ・重機 労務回送 1往復 含みます
      ・軟弱地盤の場合は別途協議願います
    TEXT
  }
]

condition_templates.each_with_index do |data, idx|
  EstimateTemplate.find_or_create_by!(template_type: "condition", name: data[:name], is_shared: true) do |t|
    t.content = data[:content]
    t.sort_order = idx
  end
end
puts "  Created #{condition_templates.size} condition templates"

# 確認書テンプレート
confirmation_content = {
  "材料費" => ["As合材", "RC-40 RM-25"],
  "施工管理" => ["写真管理", "出来形管理", "品質管理"],
  "安全費" => ["保安要員", "保安施設"],
  "仮設経費（左）" => ["看板・標識類", "保安関係費", "電気引込費", "土捨場代", "丁張材料"],
  "仮設経費（右）" => ["基本測量", "施工測量", "測量機器", "仮設道路", "工事用電気", "工事用水道", "工事用借地料", "重機仮置場", "現場事務所", "宿舎", "倉庫", "電気 水道 ガス", "借地料"],
  "その他" => ["労災保険料", "建退協証紙代"]
}.to_json

EstimateTemplate.find_or_create_by!(template_type: "confirmation", name: "標準確認書", is_shared: true) do |t|
  t.content = confirmation_content
  t.sort_order = 0
end
puts "  Created confirmation template"

# 原価内訳テンプレート
puts "Creating cost breakdown templates..."

cost_breakdown_templates = [
  # 材料費
  { name: "As合材", category: "材料費", unit: "t", default_unit_price: 15000 },
  { name: "RC-40", category: "材料費", unit: "m³", default_unit_price: 3500 },
  { name: "RM-25", category: "材料費", unit: "m³", default_unit_price: 4000 },
  { name: "生コンクリート", category: "材料費", unit: "m³", default_unit_price: 18000 },
  { name: "鉄筋", category: "材料費", unit: "t", default_unit_price: 120000 },
  { name: "型枠材", category: "材料費", unit: "m²", default_unit_price: 800 },
  { name: "塗料", category: "材料費", unit: "缶", default_unit_price: 5000 },

  # 労務費
  { name: "普通作業員", category: "労務費", unit: "人工", default_unit_price: 18000 },
  { name: "特殊作業員", category: "労務費", unit: "人工", default_unit_price: 22000 },
  { name: "交通誘導員", category: "労務費", unit: "人工", default_unit_price: 15000 },
  { name: "職長手当", category: "労務費", unit: "日", default_unit_price: 3000 },

  # 外注費
  { name: "舗装外注", category: "外注費", unit: "m²" },
  { name: "電気設備外注", category: "外注費", unit: "式" },
  { name: "配管外注", category: "外注費", unit: "式" },
  { name: "塗装外注", category: "外注費", unit: "m²" },
  { name: "重機回送", category: "外注費", unit: "回", default_unit_price: 50000 },

  # 経費
  { name: "重機損料", category: "経費", unit: "日", default_unit_price: 30000 },
  { name: "足場損料", category: "経費", unit: "月", default_unit_price: 50000 },
  { name: "仮設電気", category: "経費", unit: "月", default_unit_price: 20000 },
  { name: "仮設水道", category: "経費", unit: "月", default_unit_price: 10000 },
  { name: "産廃処分費", category: "経費", unit: "t", default_unit_price: 25000 },
  { name: "残土処分費", category: "経費", unit: "m³", default_unit_price: 3000 },
  { name: "安全対策費", category: "経費", unit: "式" },
  { name: "現場管理費", category: "経費", unit: "式" },
]

cost_breakdown_templates.each_with_index do |data, idx|
  CostBreakdownTemplate.find_or_create_by!(name: data[:name], is_shared: true) do |t|
    t.category = data[:category]
    t.unit = data[:unit] || "式"
    t.default_unit_price = data[:default_unit_price]
    t.sort_order = idx
  end
end

puts "  Created #{cost_breakdown_templates.size} cost breakdown templates"

# 単位テンプレート
puts "Creating cost units..."

CostUnit::DEFAULT_UNITS.each_with_index do |name, idx|
  CostUnit.find_or_create_by!(name: name) do |u|
    u.sort_order = idx
  end
end

puts "  Created #{CostUnit::DEFAULT_UNITS.size} cost units"

# 見積項目テンプレート
puts "Creating estimate item templates..."

estimate_item_templates = [
  # 舗装工事
  { name: "As舗装工", category: "舗装工事", unit: "m²", specification: "t=50mm" },
  { name: "As舗装工", category: "舗装工事", unit: "m²", specification: "t=40mm" },
  { name: "路盤工", category: "舗装工事", unit: "m²", specification: "RC-40 t=100mm" },
  { name: "路盤工", category: "舗装工事", unit: "m²", specification: "RM-25 t=50mm" },
  { name: "舗装版切断", category: "舗装工事", unit: "m" },
  { name: "舗装版破砕", category: "舗装工事", unit: "m²" },
  { name: "プライムコート", category: "舗装工事", unit: "m²" },
  { name: "タックコート", category: "舗装工事", unit: "m²" },

  # 土工事
  { name: "掘削工", category: "土工事", unit: "m³" },
  { name: "埋戻工", category: "土工事", unit: "m³" },
  { name: "残土処分", category: "土工事", unit: "m³" },
  { name: "床付け", category: "土工事", unit: "m²" },
  { name: "転圧工", category: "土工事", unit: "m²" },

  # コンクリート工事
  { name: "コンクリート打設", category: "コンクリート工事", unit: "m³" },
  { name: "均しコンクリート", category: "コンクリート工事", unit: "m²", specification: "t=50mm" },
  { name: "土間コンクリート", category: "コンクリート工事", unit: "m²", specification: "t=100mm" },

  # 型枠工事
  { name: "型枠工", category: "型枠工事", unit: "m²" },

  # 鉄筋工事
  { name: "鉄筋工", category: "鉄筋工事", unit: "t" },
  { name: "ワイヤーメッシュ", category: "鉄筋工事", unit: "m²" },

  # 外構工事
  { name: "縁石設置", category: "外構工事", unit: "m" },
  { name: "側溝設置", category: "外構工事", unit: "m" },
  { name: "フェンス設置", category: "外構工事", unit: "m" },
  { name: "車止め設置", category: "外構工事", unit: "箇所" },
  { name: "区画線", category: "外構工事", unit: "m" },

  # 仮設工事
  { name: "仮囲い", category: "仮設工事", unit: "m" },
  { name: "仮設電気", category: "仮設工事", unit: "式" },
  { name: "仮設水道", category: "仮設工事", unit: "式" },
  { name: "安全対策費", category: "仮設工事", unit: "式" },
  { name: "交通誘導員", category: "仮設工事", unit: "人工" },
]

estimate_item_templates.each_with_index do |data, idx|
  EstimateItemTemplate.find_or_create_by!(name: data[:name], category: data[:category], specification: data[:specification], is_shared: true) do |t|
    t.unit = data[:unit] || "式"
    t.default_unit_price = data[:default_unit_price]
    t.sort_order = idx
  end
end

puts "  Created #{estimate_item_templates.size} estimate item templates"
