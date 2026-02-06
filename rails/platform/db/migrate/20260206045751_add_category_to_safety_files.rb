class AddCategoryToSafetyFiles < ActiveRecord::Migration[8.0]
  def change
    # 案件への直接紐付け
    add_reference :safety_files, :project, foreign_key: true
    # カテゴリ（書類種類）
    add_reference :safety_files, :safety_document_type, foreign_key: true
    # フォルダをオプショナルに
    change_column_null :safety_files, :safety_folder_id, true
  end
end
