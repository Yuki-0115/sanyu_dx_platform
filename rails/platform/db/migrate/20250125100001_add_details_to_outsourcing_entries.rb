# frozen_string_literal: true

class AddDetailsToOutsourcingEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :outsourcing_entries, :quantity, :decimal, precision: 10, scale: 2
    add_column :outsourcing_entries, :unit, :string
    add_column :outsourcing_entries, :work_description, :text
  end
end
