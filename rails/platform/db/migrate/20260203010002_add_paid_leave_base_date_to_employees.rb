# frozen_string_literal: true

class AddPaidLeaveBaseDateToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :paid_leave_base_date, :date, comment: "有給基準日"
  end
end
