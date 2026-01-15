class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :tenant, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.text :site_address
      t.decimal :site_lat, precision: 10, scale: 7
      t.decimal :site_lng, precision: 10, scale: 7
      t.boolean :has_contract, default: false
      t.boolean :has_order, default: false
      t.boolean :has_payment_terms, default: false
      t.boolean :has_customer_approval, default: false
      t.datetime :four_point_completed_at
      t.jsonb :pre_construction_check
      t.datetime :pre_construction_approved_at
      t.decimal :estimated_amount, precision: 15, scale: 2
      t.decimal :order_amount, precision: 15, scale: 2
      t.decimal :budget_amount, precision: 15, scale: 2
      t.decimal :actual_cost, precision: 15, scale: 2
      t.string :status, default: "draft"
      t.integer :sales_user_id
      t.integer :engineering_user_id
      t.integer :construction_user_id
      t.text :drive_folder_url

      t.timestamps
    end

    add_index :projects, %i[tenant_id code], unique: true
    add_index :projects, :sales_user_id
    add_index :projects, :engineering_user_id
    add_index :projects, :construction_user_id
    add_index :projects, :status
  end
end
