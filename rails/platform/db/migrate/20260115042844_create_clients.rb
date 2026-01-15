class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.references :tenant, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.string :name_kana
      t.string :postal_code
      t.text :address
      t.string :phone
      t.string :contact_name
      t.string :contact_email
      t.string :payment_terms
      t.text :notes

      t.timestamps
    end
    add_index :clients, %i[tenant_id code], unique: true
  end
end
