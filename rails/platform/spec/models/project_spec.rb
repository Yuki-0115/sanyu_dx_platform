# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'バリデーション' do
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:status).in_array(Project::STATUSES) }
    it { should validate_inclusion_of(:project_type).in_array(Project::PROJECT_TYPES) }
    it { should validate_inclusion_of(:order_flow).in_array(Project::ORDER_FLOWS) }
  end

  describe 'アソシエーション' do
    it { should belong_to(:client).optional }
    it { should belong_to(:sales_user).class_name('Employee').optional }
    it { should belong_to(:engineering_user).class_name('Employee').optional }
    it { should belong_to(:construction_user).class_name('Employee').optional }
    it { should have_one(:budget).dependent(:destroy) }
    it { should have_many(:estimates).dependent(:destroy) }
    it { should have_many(:daily_reports).dependent(:restrict_with_error) }
    it { should have_many(:invoices).dependent(:restrict_with_error) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つ' do
      expect(build(:project)).to be_valid
    end

    it 'orderedトレイトが正しく動作する' do
      project = build(:project, :ordered)
      expect(project.status).to eq('ordered')
      expect(project.four_point_completed?).to be true
    end

    it 'in_progressトレイトが正しく動作する' do
      project = build(:project, :in_progress)
      expect(project.status).to eq('in_progress')
    end
  end

  describe 'コード自動生成' do
    it '作成時にコードが自動生成される' do
      project = create(:project, code: nil)
      expect(project.code).to be_present
      expect(project.code).to start_with('PJ')
    end
  end

  describe '#four_point_completed?' do
    it '4点全てがtrueの場合はtrueを返す' do
      project = build(:project,
                      has_contract: true,
                      has_order: true,
                      has_payment_terms: true,
                      has_customer_approval: true)
      expect(project.four_point_completed?).to be true
    end

    it '1つでもfalseがあればfalseを返す' do
      project = build(:project,
                      has_contract: true,
                      has_order: true,
                      has_payment_terms: false,
                      has_customer_approval: true)
      expect(project.four_point_completed?).to be false
    end
  end

  describe 'スコープ' do
    it '.activeはクローズされていない案件を返す' do
      active = create(:project, status: 'in_progress')
      closed = create(:project, status: 'closed')

      expect(Project.active).to include(active)
      expect(Project.active).not_to include(closed)
    end
  end
end
