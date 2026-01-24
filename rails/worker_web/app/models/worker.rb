# frozen_string_literal: true

# Worker Webでは「Worker」として扱うが、実際のテーブルはplatformの「employees」
# これにより両アプリでデータを共有できる
class Worker < ApplicationRecord
  self.table_name = "employees"

  # Associations
  belongs_to :partner, optional: true
  has_many :attendances, foreign_key: :employee_id

  # Validations (読み取り専用なので最低限)
  validates :code, presence: true
  validates :name, presence: true

  # Worker Web用の認証メソッド
  # パスワードが設定されている場合はDevise認証を使用
  # ない場合は生年月日4桁（MMDD）で簡易認証
  def authenticate_with_password(password)
    if encrypted_password.present?
      # Devise互換の認証
      BCrypt::Password.new(encrypted_password) == password
    else
      # 生年月日での簡易認証（将来的には廃止予定）
      birth_date.present? && password == birth_date.strftime("%m%d")
    end
  end
end
