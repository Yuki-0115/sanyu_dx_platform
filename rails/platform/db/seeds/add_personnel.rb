# frozen_string_literal: true

# 人員配置テストデータ
tenant = Tenant.find(2)
Current.tenant_id = tenant.id

puts "=== 人員配置データ作成 ==="

# 仮社員・外注がいなければ追加
if Employee.where(employment_type: "temporary").count == 0
  Employee.create!(
    code: "T001",
    name: "仮社員 太郎",
    employment_type: "temporary",
    role: "worker",
    email: "temp1@example.com",
    password: "password123"
  )
  puts "Created temporary employee: 仮社員 太郎"
end

if Employee.where(employment_type: "external").count == 0
  Employee.create!(
    code: "E001",
    name: "外注 次郎",
    employment_type: "external",
    role: "worker",
    email: "ext1@example.com",
    password: "password123"
  )
  puts "Created external employee: 外注 次郎"
end

# 社員一覧
puts "\n社員一覧:"
Employee.all.each { |e| puts "  - #{e.name} (#{e.employment_type})" }

# 案件に人員を配置
projects = Project.where(status: %w[in_progress preparing ordered]).limit(5)
employees = Employee.all.to_a

puts "\n人員配置:"
projects.each do |project|
  # ランダムに1-3人配置
  employees.sample(rand(1..3)).each do |emp|
    next if project.project_assignments.exists?(employee: emp)

    assignment = ProjectAssignment.create!(
      project: project,
      employee: emp,
      role: %w[foreman worker support].sample,
      start_date: project.scheduled_start_date || Date.current,
      end_date: project.scheduled_end_date
    )
    puts "  #{emp.name} -> #{project.code} (#{assignment.role})"
  end
end

puts "\n=== 完了 ==="
