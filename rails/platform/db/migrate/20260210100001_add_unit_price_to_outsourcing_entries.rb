class AddUnitPriceToOutsourcingEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :outsourcing_entries, :unit_price, :decimal, precision: 15, scale: 2
  end
end
