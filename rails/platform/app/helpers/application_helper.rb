module ApplicationHelper
  include ProjectsHelper
  include DailyReportsHelper

  # 雇用種別ラベル
  def employment_type_label(type)
    {
      "regular" => "正社員",
      "temporary" => "仮社員",
      "external" => "外注"
    }[type] || type
  end

  # 雇用種別バッジクラス
  def employment_type_badge_class(type)
    {
      "regular" => "bg-blue-100 text-blue-800",
      "temporary" => "bg-yellow-100 text-yellow-800",
      "external" => "bg-purple-100 text-purple-800"
    }[type] || "bg-gray-100 text-gray-800"
  end

  # 役割ラベル
  def role_label(role)
    {
      "admin" => "管理者",
      "management" => "経営層",
      "accounting" => "経理",
      "sales" => "営業",
      "engineering" => "技術",
      "construction" => "施工管理",
      "worker" => "作業員"
    }[role] || role
  end

  # 祝日判定
  def holiday?(date)
    return false unless defined?(HolidayJp)
    HolidayJp.holiday?(date)
  end

  # 祝日名取得
  def holiday_name(date)
    return nil unless defined?(HolidayJp)
    holiday = HolidayJp.between(date, date).first
    holiday&.name
  end

  # 未読メンション数
  def unread_mention_count(employee)
    return 0 unless employee

    ProjectMessage.unread_mentions_for(employee).count
  end
end
