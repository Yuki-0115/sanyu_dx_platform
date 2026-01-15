class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :partner, null: false, foreign_key: true
      t.string :code
      t.string :name
      t.string :name_kana
      t.string :email
      t.string :phone
      t.string :employment_type
      t.date :hire_date
      t.string :role

      t.timestamps
    end
    add_index :employees, :code, unique: true
    add_index :employees, :email, unique: true
  end
end
