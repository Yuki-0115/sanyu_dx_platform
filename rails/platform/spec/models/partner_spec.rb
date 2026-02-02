# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Partner, type: :model do
  describe 'バリデーション' do
    it { should validate_presence_of(:name) }
  end

  describe 'アソシエーション' do
    it { should have_many(:employees).dependent(:nullify) }
    it { should have_many(:offsets).dependent(:restrict_with_error) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つ' do
      expect(build(:partner)).to be_valid
    end
  end

  describe 'コード自動生成' do
    it '作成時にコードが自動生成される' do
      partner = create(:partner, code: nil)
      expect(partner.code).to be_present
      expect(partner.code).to start_with('PT')
    end
  end
end
