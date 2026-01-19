# frozen_string_literal: true

# Create default tenant
tenant = Tenant.find_by(code: "sunyutech") || Tenant.find_by(code: "sanyu") || Tenant.create!(code: "sunyutech", name: "sunyutech")
tenant.update!(code: "sunyutech", name: "sunyutech") if tenant.code != "sunyutech"

puts "Created tenant: #{tenant.name}"

# Temporarily set current tenant for seeding
Current.tenant_id = tenant.id

# Create admin employee
admin = Employee.unscoped.find_by(email: "admin@sanyu.example.com")
unless admin
  admin = Employee.new(
    tenant: tenant, code: "EMP001", name: "管理者",
    email: "admin@sanyu.example.com", employment_type: "regular",
    role: "admin", password: "password123", password_confirmation: "password123"
  )
  admin.save!
end

puts "Created admin: #{admin.email} (password: password123)"

# Create management employee
manager = Employee.unscoped.find_by(email: "manager@sanyu.example.com")
unless manager
  manager = Employee.new(
    tenant: tenant, code: "EMP002", name: "経営担当",
    email: "manager@sanyu.example.com", employment_type: "regular",
    role: "management", password: "password123", password_confirmation: "password123"
  )
  manager.save!
end

puts "Created manager: #{manager.email} (password: password123)"

# Create construction employee
foreman = Employee.unscoped.find_by(email: "foreman@sanyu.example.com")
unless foreman
  foreman = Employee.new(
    tenant: tenant, code: "EMP003", name: "職長太郎",
    email: "foreman@sanyu.example.com", employment_type: "regular",
    role: "construction", password: "password123", password_confirmation: "password123"
  )
  foreman.save!
end

puts "Created foreman: #{foreman.email} (password: password123)"

# Create sample clients
client1 = Client.find_or_create_by!(code: "CLI001") do |c|
  c.tenant = tenant
  c.name = "株式会社テスト建設"
end

client2 = Client.find_or_create_by!(code: "CLI002") do |c|
  c.tenant = tenant
  c.name = "サンプル工業株式会社"
end

puts "Created clients: #{client1.name}, #{client2.name}"

# Create sample project
project = Project.find_or_create_by!(code: "PJ001") do |p|
  p.tenant = tenant
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
  p.tenant = tenant
  p.name = "協力建設株式会社"
  p.has_temporary_employees = true
end

partner2 = Partner.find_or_create_by!(code: "PTN002") do |p|
  p.tenant = tenant
  p.name = "テスト工業"
  p.has_temporary_employees = true
end

# 外注会社（原価管理対象）
partner3 = Partner.find_or_create_by!(code: "PTN003") do |p|
  p.tenant = tenant
  p.name = "大和電設"
  p.has_temporary_employees = false
end

partner4 = Partner.find_or_create_by!(code: "PTN004") do |p|
  p.tenant = tenant
  p.name = "関東配管工業"
  p.has_temporary_employees = false
end

partner5 = Partner.find_or_create_by!(code: "PTN005") do |p|
  p.tenant = tenant
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
  emp = Employee.unscoped.find_by(code: data[:code])
  unless emp
    emp = Employee.new(
      tenant: tenant,
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
  p.tenant = tenant
  p.name = "駅前ビル改修工事"
  p.client = client2
  p.sales_user = manager
  p.status = "in_progress"
  p.estimated_amount = 30_000_000
  p.scheduled_start_date = Date.current.beginning_of_month
  p.scheduled_end_date = Date.current.end_of_month + 2.months
end

project3 = Project.find_or_create_by!(code: "PJ003") do |p|
  p.tenant = tenant
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
      tenant: tenant,
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
          tenant: tenant,
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
        unless OutsourcingEntry.exists?(tenant: tenant, daily_report: daily_report, partner: partner)
          OutsourcingEntry.create!(
            tenant: tenant,
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

puts "\n=== Seed completed ==="
puts "Login with: admin@sanyu.example.com / password123"
