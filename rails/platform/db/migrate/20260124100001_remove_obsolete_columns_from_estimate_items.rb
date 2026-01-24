# frozen_string_literal: true

class RemoveObsoleteColumnsFromEstimateItems < ActiveRecord::Migration[8.0]
  def change
    # 旧方式のカテゴリ文字列カラムを削除
    # 現在は estimate_category_id で工種を管理しているため不要
    remove_column :estimate_items, :category, :string
  end
end
