# frozen_string_literal: true

class AddFieldsToEstimates < ActiveRecord::Migration[8.0]
  def change
    add_column :estimates, :recipient, :string
    add_column :estimates, :subject, :string
    add_column :estimates, :location, :string
    add_column :estimates, :period_start, :date
    add_column :estimates, :period_end, :date
    add_column :estimates, :validity_period, :string, default: "3ヵ月"
    add_column :estimates, :payment_terms, :text
    add_column :estimates, :waste_disposal_note, :text
    add_column :estimates, :special_note, :text
    add_column :estimates, :person_in_charge, :string
    add_column :estimates, :overhead_rate, :decimal, precision: 5, scale: 2, default: 4.0
    add_column :estimates, :welfare_rate, :decimal, precision: 5, scale: 2, default: 3.0
    add_column :estimates, :adjustment, :integer, default: 0
    add_column :estimates, :conditions, :text
  end
end
