# frozen_string_literal: true

class AllowNullClientIdOnProjects < ActiveRecord::Migration[8.0]
  def change
    change_column_null :projects, :client_id, true
  end
end
