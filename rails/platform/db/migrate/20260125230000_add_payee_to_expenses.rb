# frozen_string_literal: true

class AddPayeeToExpenses < ActiveRecord::Migration[8.0]
  def change
    # 支払先（店舗名、会社名など）
    add_column :expenses, :payee_name, :string
  end
end
