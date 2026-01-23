# frozen_string_literal: true

class AddEstimateMemoToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :estimate_memo, :text
  end
end
