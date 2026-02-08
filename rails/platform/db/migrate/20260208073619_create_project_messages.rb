class CreateProjectMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :project_messages do |t|
      t.references :project, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.text :content, null: false

      t.timestamps
    end

    add_index :project_messages, [:project_id, :created_at]
  end
end
