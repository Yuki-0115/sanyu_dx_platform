# frozen_string_literal: true

class SplitHighwayEntryRoute < ActiveRecord::Migration[8.0]
  def change
    add_column :highway_entries, :route_from, :string
    add_column :highway_entries, :route_to, :string
    remove_column :highway_entries, :route, :string
  end
end
