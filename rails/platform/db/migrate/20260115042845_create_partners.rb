class CreatePartners < ActiveRecord::Migration[8.0]
  def change
    create_table :partners do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :has_temporary_employees, default: false
      t.string :offset_rule
      t.integer :closing_day
      t.decimal :carryover_balance, precision: 15, scale: 2, default: 0

      t.timestamps
    end
    add_index :partners, %i[tenant_id code], unique: true
  end
end
