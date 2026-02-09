# frozen_string_literal: true

class AddMentionFieldsToProjectMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :project_messages, :mentioned_user_ids, :integer, array: true, default: []
    add_index :project_messages, :mentioned_user_ids, using: :gin
  end
end
