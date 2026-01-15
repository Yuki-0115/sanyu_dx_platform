class CreateOffsets < ActiveRecord::Migration[8.0]
  def change
    create_table :offsets do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :partner, null: false, foreign_key: true
      t.string :year_month, null: false
      t.decimal :total_salary, precision: 15, scale: 2, default: 0
      t.decimal :social_insurance, precision: 15, scale: 2, default: 0
      t.decimal :offset_amount, precision: 15, scale: 2, default: 0
      t.decimal :revenue_amount, precision: 15, scale: 2, default: 0
      t.decimal :balance, precision: 15, scale: 2, default: 0
      t.string :status, default: "draft"
      t.integer :confirmed_by_id
      t.datetime :confirmed_at

      t.timestamps
    end

    add_index :offsets, %i[tenant_id partner_id year_month], unique: true
    add_index :offsets, :confirmed_by_id
  end
end
