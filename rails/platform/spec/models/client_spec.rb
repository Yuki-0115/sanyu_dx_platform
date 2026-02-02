# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'バリデーション' do
    it { should validate_presence_of(:name) }
  end

  describe 'アソシエーション' do
    it { should have_many(:projects).dependent(:restrict_with_error) }
  end

  describe 'ファクトリ' do
    it '有効なファクトリを持つ' do
      expect(build(:client)).to be_valid
    end
  end

  describe 'コード自動生成' do
    it '作成時にコードが自動生成される' do
      client = create(:client, code: nil)
      expect(client.code).to be_present
      expect(client.code).to start_with('CL')
    end
  end
end
