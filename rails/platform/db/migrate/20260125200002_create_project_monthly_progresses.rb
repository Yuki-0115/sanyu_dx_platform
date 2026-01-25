class CreateProjectMonthlyProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :project_monthly_progresses do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :progress_amount, precision: 12, scale: 0, default: 0
      t.string :note

      t.timestamps
    end

    add_index :project_monthly_progresses, [:project_id, :year, :month], unique: true, name: 'idx_project_monthly_progress_unique'
  end
end
