class CreatePartners < ActiveRecord::Migration[8.0]
  def change
    create_table :partners do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :code
      t.string :name
      t.boolean :has_temporary_employees
      t.string :offset_rule
      t.integer :closing_day
      t.decimal :carryover_balance

      t.timestamps
    end
    add_index :partners, :code, unique: true
  end
end
