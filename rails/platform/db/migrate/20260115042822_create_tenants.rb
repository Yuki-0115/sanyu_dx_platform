class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :tenants, :code, unique: true
  end
end
