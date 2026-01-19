class CreateOutsourcingEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :outsourcing_entries do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :daily_report, null: false, foreign_key: true
      t.references :partner, foreign_key: true  # マスタから選択（任意）
      t.string :partner_name                     # 手入力用（マスタにない場合）
      t.integer :headcount, null: false, default: 1
      t.string :attendance_type, null: false, default: 'full'

      t.timestamps
    end

    add_index :outsourcing_entries, [:tenant_id, :daily_report_id, :partner_id],
              name: 'idx_outsourcing_entries_unique_partner',
              unique: true,
              where: 'partner_id IS NOT NULL'
  end
end
