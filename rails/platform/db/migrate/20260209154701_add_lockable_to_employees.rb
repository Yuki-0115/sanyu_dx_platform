# frozen_string_literal: true

class AddLockableToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :failed_attempts, :integer, default: 0, null: false
    add_column :employees, :unlock_token, :string
    add_column :employees, :locked_at, :datetime
    add_index :employees, :unlock_token, unique: true
  end
end
