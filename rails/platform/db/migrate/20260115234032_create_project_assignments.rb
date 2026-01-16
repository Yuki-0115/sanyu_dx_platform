class CreateProjectAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :project_assignments do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.string :role
      t.text :notes

      t.timestamps
    end

    add_index :project_assignments, %i[tenant_id project_id employee_id], unique: true, name: "idx_project_assignments_unique"
  end
end
