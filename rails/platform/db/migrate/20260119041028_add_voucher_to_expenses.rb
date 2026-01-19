class AddVoucherToExpenses < ActiveRecord::Migration[8.0]
  def change
    add_column :expenses, :voucher_number, :string
  end
end
