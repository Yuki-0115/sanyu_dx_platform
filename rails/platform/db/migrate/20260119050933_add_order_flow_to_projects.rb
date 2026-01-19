class AddOrderFlowToProjects < ActiveRecord::Migration[8.0]
  def change
    # 受注フロー種別
    # standard: 見積→注文書→受注（通常フロー）
    # oral_first: 口頭受注→後から注文書（先行着工パターン）
    add_column :projects, :order_flow, :string, default: "standard"

    # 口頭受注日（oral_first フローで使用）
    add_column :projects, :oral_order_received_at, :datetime

    # 注文書受領日（oral_first フローで後から記録）
    add_column :projects, :order_document_received_at, :datetime

    # 口頭受注時の金額メモ
    add_column :projects, :oral_order_amount, :decimal, precision: 15, scale: 2

    # 口頭受注の備考
    add_column :projects, :oral_order_note, :text
  end
end
