# frozen_string_literal: true

class AddSafetyDocPersonToProjects < ActiveRecord::Migration[8.0]
  def change
    add_reference :projects, :safety_doc_person, foreign_key: { to_table: :employees }, null: true
  end
end
