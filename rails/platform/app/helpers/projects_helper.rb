# frozen_string_literal: true

module ProjectsHelper
  STATUS_LABELS = {
    "draft" => "下書き",
    "estimating" => "見積中",
    "ordered" => "受注済",
    "preparing" => "着工準備中",
    "in_progress" => "施工中",
    "completed" => "完工",
    "invoiced" => "請求済",
    "paid" => "入金済",
    "closed" => "クローズ"
  }.freeze

  STATUS_BADGE_CLASSES = {
    "draft" => "bg-gray-100 text-gray-800",
    "estimating" => "bg-yellow-100 text-yellow-800",
    "ordered" => "bg-blue-100 text-blue-800",
    "preparing" => "bg-purple-100 text-purple-800",
    "in_progress" => "bg-green-100 text-green-800",
    "completed" => "bg-teal-100 text-teal-800",
    "invoiced" => "bg-orange-100 text-orange-800",
    "paid" => "bg-emerald-100 text-emerald-800",
    "closed" => "bg-gray-100 text-gray-600"
  }.freeze

  def status_label(status)
    STATUS_LABELS[status] || status
  end

  def status_badge_class(status)
    STATUS_BADGE_CLASSES[status] || "bg-gray-100 text-gray-800"
  end
end
