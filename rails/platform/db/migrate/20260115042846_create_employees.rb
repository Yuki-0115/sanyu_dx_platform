class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :partner, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :name_kana
      t.string :email
      t.string :phone
      t.string :employment_type, null: false
      t.date :hire_date
      t.string :role, null: false

      t.timestamps
    end
    add_index :employees, %i[tenant_id code], unique: true
    add_index :employees, %i[tenant_id email], unique: true
    add_index :employees, :employment_type
    add_index :employees, :role
  end
end
