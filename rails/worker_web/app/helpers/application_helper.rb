# frozen_string_literal: true

module ApplicationHelper
  ATTENDANCE_TYPE_LABELS = {
    "full" => "通常",
    "half" => "半日",
    "overtime" => "残業",
    "holiday" => "休日",
    "night" => "夜勤"
  }.freeze

  ATTENDANCE_TYPE_CLASSES = {
    "full" => "bg-green-100 text-green-700",
    "half" => "bg-yellow-100 text-yellow-700",
    "overtime" => "bg-blue-100 text-blue-700",
    "holiday" => "bg-red-100 text-red-700",
    "night" => "bg-purple-100 text-purple-700"
  }.freeze

  PROJECT_STATUS_LABELS = {
    "draft" => "下書き",
    "estimating" => "見積中",
    "ordered" => "受注",
    "preparing" => "準備中",
    "in_progress" => "施工中",
    "completed" => "完工",
    "invoiced" => "請求済",
    "paid" => "入金済",
    "closed" => "完了"
  }.freeze

  PROJECT_STATUS_CLASSES = {
    "draft" => "bg-gray-100 text-gray-700",
    "estimating" => "bg-yellow-100 text-yellow-700",
    "ordered" => "bg-blue-100 text-blue-700",
    "preparing" => "bg-indigo-100 text-indigo-700",
    "in_progress" => "bg-green-100 text-green-700",
    "completed" => "bg-teal-100 text-teal-700",
    "invoiced" => "bg-purple-100 text-purple-700",
    "paid" => "bg-emerald-100 text-emerald-700",
    "closed" => "bg-gray-100 text-gray-700"
  }.freeze

  def attendance_type_label(type)
    ATTENDANCE_TYPE_LABELS[type] || type
  end

  def attendance_type_class(type)
    ATTENDANCE_TYPE_CLASSES[type] || "bg-gray-100 text-gray-700"
  end

  def project_status_label(status)
    PROJECT_STATUS_LABELS[status] || status
  end

  def project_status_class(status)
    PROJECT_STATUS_CLASSES[status] || "bg-gray-100 text-gray-700"
  end
end
