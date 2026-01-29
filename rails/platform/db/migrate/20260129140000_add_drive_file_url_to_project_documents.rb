# frozen_string_literal: true

class AddDriveFileUrlToProjectDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :project_documents, :drive_file_url, :string
  end
end
