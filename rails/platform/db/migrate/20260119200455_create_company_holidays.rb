class CreateCompanyHolidays < ActiveRecord::Migration[8.0]
  def change
    create_table :company_holidays do |t|
      t.date :holiday_date, null: false
      t.string :calendar_type, null: false  # 'worker' or 'office'
      t.string :name
      t.text :description

      t.timestamps
    end

    add_index :company_holidays, [:holiday_date, :calendar_type], unique: true
    add_index :company_holidays, :calendar_type
    add_index :company_holidays, :holiday_date
  end
end
