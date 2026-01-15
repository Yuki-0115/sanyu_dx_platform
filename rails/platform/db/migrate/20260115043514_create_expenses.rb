class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :daily_report, foreign_key: true
      t.references :project, foreign_key: true
      t.string :expense_type, null: false
      t.string :category, null: false
      t.text :description
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.references :payer, foreign_key: { to_table: :employees }
      t.string :payment_method
      t.string :status, default: "pending"
      t.integer :approved_by_id
      t.datetime :approved_at

      t.timestamps
    end

    add_index :expenses, :approved_by_id
  end
end
