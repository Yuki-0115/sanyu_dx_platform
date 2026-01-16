# frozen_string_literal: true

class AddScheduleDatesToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :scheduled_start_date, :date
    add_column :projects, :scheduled_end_date, :date
    add_column :projects, :actual_start_date, :date
    add_column :projects, :actual_end_date, :date

    add_index :projects, :scheduled_start_date
    add_index :projects, :scheduled_end_date
  end
end
