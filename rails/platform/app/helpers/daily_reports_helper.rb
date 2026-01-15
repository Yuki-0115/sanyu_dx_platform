# frozen_string_literal: true

module DailyReportsHelper
  STATUS_LABELS = {
    "draft" => "下書き",
    "confirmed" => "確定済",
    "revised" => "修正済"
  }.freeze

  STATUS_CLASSES = {
    "draft" => "bg-yellow-100 text-yellow-800",
    "confirmed" => "bg-green-100 text-green-800",
    "revised" => "bg-blue-100 text-blue-800"
  }.freeze

  def daily_report_status_label(status)
    STATUS_LABELS[status] || status
  end

  def daily_report_status_class(status)
    STATUS_CLASSES[status] || "bg-gray-100 text-gray-800"
  end
end
