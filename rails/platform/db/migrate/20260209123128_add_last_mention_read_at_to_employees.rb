# frozen_string_literal: true

class AddLastMentionReadAtToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :last_mention_read_at, :datetime
  end
end
