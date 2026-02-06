class CreateCostUnits < ActiveRecord::Migration[8.0]
  def change
    create_table :cost_units do |t|
      t.string :name, null: false
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :cost_units, :name, unique: true
    add_index :cost_units, :sort_order
  end
end
