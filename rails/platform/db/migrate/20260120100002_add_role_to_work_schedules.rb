class AddRoleToWorkSchedules < ActiveRecord::Migration[8.0]
  def change
    add_column :work_schedules, :role, :string, default: "worker"
  end
end
