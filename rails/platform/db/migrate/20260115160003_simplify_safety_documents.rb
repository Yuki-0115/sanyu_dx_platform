# frozen_string_literal: true

class SimplifySafetyDocuments < ActiveRecord::Migration[8.0]
  def change
    # 既存のsafety_documentsテーブルを削除（存在する場合のみ）
    drop_table :safety_documents if table_exists?(:safety_documents)
    drop_table :safety_files if table_exists?(:safety_files)
    drop_table :safety_folders if table_exists?(:safety_folders)

    # 安全書類フォルダ
    create_table :safety_folders do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.string :name, null: false  # フォルダ名
      t.text :description          # 説明
      t.integer :files_count, default: 0  # ファイル数（キャッシュ）

      t.timestamps
    end

    add_index :safety_folders, [:tenant_id, :project_id]
    add_index :safety_folders, [:tenant_id, :name]

    # 安全書類ファイル
    create_table :safety_files do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :safety_folder, null: false, foreign_key: true
      t.string :name, null: false           # ファイル名（表示用）
      t.text :description                   # 説明・メモ
      t.bigint :uploaded_by_id              # アップロード者

      t.timestamps
    end

    add_foreign_key :safety_files, :employees, column: :uploaded_by_id
  end
end
