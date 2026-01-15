class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :invoice, null: false, foreign_key: true
      t.date :payment_date, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.text :notes

      t.timestamps
    end
  end
end
