class CreateMonthlyWips < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_wips do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :revenue, precision: 15, scale: 0, default: 0, comment: "仕掛かり売上（出来高金額）"
      t.decimal :cost, precision: 15, scale: 0, default: 0, comment: "仕掛かり原価（材料先行発注等）"
      t.text :note

      t.timestamps
    end

    add_index :monthly_wips, [:year, :month]
    add_index :monthly_wips, [:project_id, :year, :month], unique: true
  end
end
