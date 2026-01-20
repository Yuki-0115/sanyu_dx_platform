class CreateCompanyEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :company_events do |t|
      t.date :event_date, null: false
      t.string :name, null: false
      t.text :description
      t.string :calendar_type, null: false, default: "all"
      t.string :color, default: "purple"

      t.timestamps
    end

    add_index :company_events, :event_date
    add_index :company_events, :calendar_type
    add_index :company_events, [:event_date, :calendar_type]
  end
end
