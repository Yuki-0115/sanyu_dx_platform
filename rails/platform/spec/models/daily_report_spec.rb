# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DailyReport, type: :model do
  describe 'バリデーション' do
    it { should validate_presence_of(:report_date) }
    it { should validate_inclusion_of(:status).in_array(DailyReport::STATUSES) }
  end

  describe 'アソシエーション' do
    it { should belong_to(:project).optional }
    it { should belong_to(:foreman).class_name('Employee') }
    it { should have_many(:attendances).dependent(:destroy) }
    it { should have_many(:expenses).dependent(:destroy) }
    it { should have_many(:outsourcing_entries).dependent(:destroy) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つ' do
      # project_idのバリデーションがあるため、createで関連を保存する必要がある
      project = create(:project)
      foreman = create(:employee)
      report = build(:daily_report, project: project, foreman: foreman)
      expect(report).to be_valid
    end

    it 'confirmedトレイトが正しく動作する' do
      report = build(:daily_report, :confirmed)
      expect(report.status).to eq('confirmed')
      expect(report.confirmed?).to be true
    end

    it 'externalトレイトが正しく動作する' do
      report = build(:daily_report, :external)
      expect(report.is_external).to be true
      expect(report.project).to be_nil
    end
  end

  describe '#confirm!' do
    it 'ステータスをconfirmedに変更する' do
      project = create(:project)
      foreman = create(:employee)
      report = create(:daily_report, project: project, foreman: foreman)
      report.confirm!
      expect(report.status).to eq('confirmed')
      expect(report.confirmed_at).to be_present
    end
  end

  describe '#site_name' do
    it '内部案件の場合は案件名を返す' do
      project = create(:project)
      foreman = create(:employee)
      report = build(:daily_report, project: project, foreman: foreman)
      expect(report.site_name).to eq(project.name)
    end

    it '外部案件の場合は外部現場名を返す' do
      foreman = create(:employee)
      report = build(:daily_report, :external, foreman: foreman)
      expect(report.site_name).to eq('外部現場A')
    end
  end
end
