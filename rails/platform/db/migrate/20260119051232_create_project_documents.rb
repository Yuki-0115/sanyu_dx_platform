class CreateProjectDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :project_documents do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :uploaded_by, foreign_key: { to_table: :employees }
      t.string :name, null: false
      t.string :category, null: false, default: "other"
      t.text :description
      t.date :document_date

      t.timestamps
    end

    add_index :project_documents, [:project_id, :category]
  end
end
