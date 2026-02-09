# frozen_string_literal: true

# 案件チャットメッセージ
class ProjectMessage < ApplicationRecord
  include Auditable

  belongs_to :project
  belongs_to :employee

  validates :content, presence: true, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc) }
  scope :latest, ->(n = 5) { order(created_at: :desc).limit(n) }
  scope :with_mention_to, ->(employee_id) { where("? = ANY(mentioned_user_ids)", employee_id) }
  scope :unread_mentions_for, ->(employee) { with_mention_to(employee.id).where("created_at > ?", employee.last_mention_read_at || 100.years.ago) }

  before_save :parse_mentions

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

  # メンションされた社員一覧
  def mentioned_employees
    return Employee.none if mentioned_user_ids.blank?

    Employee.where(id: mentioned_user_ids)
  end

  # メンションをハイライト表示用に変換
  def content_with_highlighted_mentions
    return content if mentioned_user_ids.blank?

    result = content.dup
    mentioned_employees.each do |emp|
      result.gsub!(/@#{Regexp.escape(emp.name)}/, "<span class=\"text-blue-600 font-bold\">@#{emp.name}</span>")
    end
    result.html_safe
  end

  private

  # content内の@名前をパースしてmentioned_user_idsに格納
  def parse_mentions
    return if content.blank?

    # @の後に続く名前を抽出
    mention_names = content.scan(/@(\S+)/).flatten
    return if mention_names.empty?

    # 名前から社員を検索
    employees = Employee.active.where(name: mention_names)
    self.mentioned_user_ids = employees.pluck(:id).uniq
  end
end
