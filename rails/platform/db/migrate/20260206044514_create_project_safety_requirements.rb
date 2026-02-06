class CreateProjectSafetyRequirements < ActiveRecord::Migration[8.0]
  def change
    create_table :project_safety_requirements do |t|
      t.references :project, null: false, foreign_key: true
      t.references :safety_document_type, null: false, foreign_key: true

      t.timestamps
    end

    add_index :project_safety_requirements, [:project_id, :safety_document_type_id],
              unique: true, name: "idx_project_safety_requirements_unique"
  end
end
