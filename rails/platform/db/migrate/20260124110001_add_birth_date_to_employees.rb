# frozen_string_literal: true

class AddBirthDateToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :birth_date, :date
  end
end
