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

puts "Created partners: #{partner1.name}, #{partner2.name}"

puts "\n=== Seed completed ==="
puts "Login with: admin@sanyu.example.com / password123"
