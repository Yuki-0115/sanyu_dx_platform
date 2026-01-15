class AddDeviseToEmployees < ActiveRecord::Migration[8.0]
  def change
    add_column :employees, :encrypted_password, :string, null: false, default: ""
    add_column :employees, :reset_password_token, :string
    add_column :employees, :reset_password_sent_at, :datetime
    add_column :employees, :remember_created_at, :datetime
    add_column :employees, :sign_in_count, :integer, default: 0, null: false
    add_column :employees, :current_sign_in_at, :datetime
    add_column :employees, :last_sign_in_at, :datetime
    add_column :employees, :current_sign_in_ip, :string
    add_column :employees, :last_sign_in_ip, :string

    add_index :employees, :reset_password_token, unique: true
  end
end
