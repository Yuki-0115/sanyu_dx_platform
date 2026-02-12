# frozen_string_literal: true

class AddAmountPendingToExpenses < ActiveRecord::Migration[8.0]
  def change
    add_column :expenses, :amount_pending, :boolean, default: false
  end
end
