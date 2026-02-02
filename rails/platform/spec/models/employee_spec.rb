# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Employee, type: :model do
  describe 'バリデーション' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:employment_type) }
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:employment_type).in_array(Employee::EMPLOYMENT_TYPES) }
    it { should validate_inclusion_of(:role).in_array(Employee::ROLES) }
  end

  describe 'アソシエーション' do
    it { should belong_to(:partner).optional }
    it { should have_many(:project_assignments).dependent(:destroy) }
    it { should have_many(:projects).through(:project_assignments) }
    it { should have_many(:attendances).dependent(:restrict_with_error) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つ' do
      expect(build(:employee)).to be_valid
    end

    it 'adminトレイトが正しく動作する' do
      admin = build(:employee, :admin)
      expect(admin.role).to eq('admin')
      expect(admin.admin?).to be true
    end

    it 'temporaryトレイトが正しく動作する' do
      temporary = build(:employee, :temporary)
      expect(temporary.employment_type).to eq('temporary')
      expect(temporary.temporary?).to be true
    end
  end

  describe '#can_access?' do
    let(:admin) { build(:employee, :admin) }
    let(:worker) { build(:employee, role: 'worker') }

    it 'adminは全てにアクセスできる' do
      expect(admin.can_access?(:projects)).to be true
      expect(admin.can_access?(:accounting)).to be true
      expect(admin.can_access?(:master)).to be true
    end

    it 'workerは限られた機能にのみアクセスできる' do
      expect(worker.can_access?(:dashboard)).to be true
      expect(worker.can_access?(:daily_reports)).to be true
      expect(worker.can_access?(:accounting)).to be false
      expect(worker.can_access?(:master)).to be false
    end
  end

  describe 'コード自動生成' do
    it '作成時にコードが自動生成される' do
      employee = create(:employee, code: nil)
      expect(employee.code).to be_present
      expect(employee.code).to start_with('EMP')
    end
  end
end
