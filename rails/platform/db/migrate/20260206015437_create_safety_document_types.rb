class CreateSafetyDocumentTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :safety_document_types do |t|
      t.string :name, null: false
      t.string :description
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :safety_document_types, :position
    add_index :safety_document_types, :active
  end
end
