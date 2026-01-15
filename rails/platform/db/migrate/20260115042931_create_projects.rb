class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :code
      t.string :name
      t.text :site_address
      t.decimal :site_lat
      t.decimal :site_lng
      t.boolean :has_contract
      t.boolean :has_order
      t.boolean :has_payment_terms
      t.boolean :has_customer_approval
      t.datetime :four_point_completed_at
      t.jsonb :pre_construction_check
      t.datetime :pre_construction_approved_at
      t.decimal :estimated_amount
      t.decimal :order_amount
      t.decimal :budget_amount
      t.decimal :actual_cost
      t.string :status
      t.integer :sales_user_id
      t.integer :engineering_user_id
      t.integer :construction_user_id
      t.text :drive_folder_url

      t.timestamps
    end
    add_index :projects, :code, unique: true
  end
end
