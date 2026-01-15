require 'rails_helper'

RSpec.describe Employee, type: :model do
  let(:tenant) { Tenant.create!(code: "test", name: "Test Tenant") }

  before do
    Current.tenant_id = tenant.id
  end

  describe "validations" do
    it "requires code" do
      employee = Employee.new(tenant: tenant, name: "Test", email: "test@example.com",
                              employment_type: "regular", role: "admin", password: "password123")
      expect(employee).not_to be_valid
      expect(employee.errors[:code]).to include("can't be blank")
    end

    it "requires name" do
      employee = Employee.new(tenant: tenant, code: "EMP001", email: "test@example.com",
                              employment_type: "regular", role: "admin", password: "password123")
      expect(employee).not_to be_valid
      expect(employee.errors[:name]).to include("can't be blank")
    end
  end

  describe "#can_access?" do
    let(:admin) do
      Employee.create!(tenant: tenant, code: "EMP001", name: "Admin",
                       email: "admin@example.com", employment_type: "regular",
                       role: "admin", password: "password123")
    end

    let(:management) do
      Employee.create!(tenant: tenant, code: "EMP002", name: "Manager",
                       email: "manager@example.com", employment_type: "regular",
                       role: "management", password: "password123")
    end

    let(:worker) do
      Employee.create!(tenant: tenant, code: "EMP003", name: "Worker",
                       email: "worker@example.com", employment_type: "regular",
                       role: "worker", password: "password123")
    end

    describe "admin role" do
      it "can access all features" do
        expect(admin.can_access?(:dashboard)).to be true
        expect(admin.can_access?(:projects)).to be true
        expect(admin.can_access?(:invoices)).to be true
        expect(admin.can_access?(:anything)).to be true
      end
    end

    describe "management role" do
      it "can access management features" do
        expect(management.can_access?(:dashboard)).to be true
        expect(management.can_access?(:projects)).to be true
        expect(management.can_access?(:daily_reports)).to be true
      end

      it "cannot access worker-only features" do
        expect(management.can_access?(:expenses)).to be false
      end
    end

    describe "worker role" do
      it "can access worker features" do
        expect(worker.can_access?(:daily_reports)).to be true
        expect(worker.can_access?(:attendances)).to be true
      end

      it "cannot access management features" do
        expect(worker.can_access?(:dashboard)).to be false
        expect(worker.can_access?(:projects)).to be false
        expect(worker.can_access?(:invoices)).to be false
      end
    end
  end

  describe "role check methods" do
    let(:admin) do
      Employee.create!(tenant: tenant, code: "EMP001", name: "Admin",
                       email: "admin@example.com", employment_type: "regular",
                       role: "admin", password: "password123")
    end

    it "responds to role? methods" do
      expect(admin.admin?).to be true
      expect(admin.management?).to be false
      expect(admin.worker?).to be false
    end
  end
end
