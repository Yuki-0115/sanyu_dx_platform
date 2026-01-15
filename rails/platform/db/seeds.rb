# frozen_string_literal: true

# Create default tenant
tenant = Tenant.find_or_create_by!(code: "sanyu") do |t|
  t.name = "三友テック株式会社"
end

puts "Created tenant: #{tenant.name}"

# Temporarily set current tenant for seeding
Current.tenant_id = tenant.id

# Create admin employee
admin = Employee.find_or_create_by!(email: "admin@sanyu.example.com") do |e|
  e.tenant = tenant
  e.code = "EMP001"
  e.name = "管理者"
  e.employment_type = "regular"
  e.role = "admin"
  e.password = "password123"
  e.password_confirmation = "password123"
end

puts "Created admin: #{admin.email} (password: password123)"

# Create management employee
manager = Employee.find_or_create_by!(email: "manager@sanyu.example.com") do |e|
  e.tenant = tenant
  e.code = "EMP002"
  e.name = "経営担当"
  e.employment_type = "regular"
  e.role = "management"
  e.password = "password123"
  e.password_confirmation = "password123"
end

puts "Created manager: #{manager.email} (password: password123)"

# Create construction employee
foreman = Employee.find_or_create_by!(email: "foreman@sanyu.example.com") do |e|
  e.tenant = tenant
  e.code = "EMP003"
  e.name = "職長太郎"
  e.employment_type = "regular"
  e.role = "construction"
  e.password = "password123"
  e.password_confirmation = "password123"
end

puts "Created foreman: #{foreman.email} (password: password123)"

puts "\n=== Seed completed ==="
puts "Login with: admin@sanyu.example.com / password123"
