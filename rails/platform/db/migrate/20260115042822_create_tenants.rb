class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
    add_index :tenants, :code, unique: true
  end
end
