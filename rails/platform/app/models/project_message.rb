# frozen_string_literal: true

# 案件チャットメッセージ
class ProjectMessage < ApplicationRecord
  include Auditable

  belongs_to :project
  belongs_to :employee

  validates :content, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, ->(n = 5) { order(created_at: :desc).limit(n) }

  def sender_name
    employee&.name || "不明"
  end

  def sender_role_label
    case employee&.role
    when "admin" then "管理者"
    when "management" then "経営"
    when "accounting" then "経理"
    when "sales" then "営業"
    when "engineering" then "工務"
    when "construction" then "施工"
    else ""
    end
  end
end
