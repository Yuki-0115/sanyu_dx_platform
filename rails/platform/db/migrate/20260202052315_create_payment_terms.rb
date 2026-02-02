# frozen_string_literal: true

class CreatePaymentTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_terms do |t|
      # Polymorphic association (Client or Partner)
      t.references :termable, polymorphic: true, null: false

      t.string :name, null: false
      t.integer :closing_day, null: false            # 締め日 (1-31, 0=末日)
      t.integer :payment_month_offset, default: 1    # 支払月 (0=当月, 1=翌月, 2=翌々月)
      t.integer :payment_day, null: false            # 支払日 (1-31, 0=末日)
      t.boolean :is_default, default: false
      t.text :notes

      t.timestamps
    end

    add_index :payment_terms, %i[termable_type termable_id]
    add_index :payment_terms, %i[termable_type termable_id is_default],
              name: "index_payment_terms_on_termable_and_default"
  end
end
