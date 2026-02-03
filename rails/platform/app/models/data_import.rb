# frozen_string_literal: true

class DataImport < ApplicationRecord
  belongs_to :imported_by, class_name: "Employee", optional: true

  IMPORT_TYPES = %w[clients partners employees projects paid_leaves offsets invoices cash_flow_entries].freeze
  STATUSES = %w[pending validating previewing completed failed].freeze

  validates :import_type, presence: true, inclusion: { in: IMPORT_TYPES }
  validates :status, inclusion: { in: STATUSES }

  # Step制の依存関係定義
  STEP_DEPENDENCIES = {
    "clients"            => [],                          # Step 1: 依存なし
    "partners"           => [],                          # Step 2: 依存なし
    "employees"          => [],                          # Step 3: 依存なし（協力会社は任意）
    "projects"           => %w[clients],                 # Step 4: 顧客が必要
    "paid_leaves"        => %w[employees],               # Step 5: 社員が必要
    "offsets"            => %w[partners],                # Step 6: 協力会社が必要
    "invoices"           => %w[projects],                # Step 7: 案件が必要
    "cash_flow_entries"  => %w[projects]                 # Step 8: 案件が必要
  }.freeze

  STEP_ORDER = %w[clients partners employees projects paid_leaves offsets invoices cash_flow_entries].freeze

  STEP_LABELS = {
    "clients"            => "顧客マスタ",
    "partners"           => "協力会社マスタ",
    "employees"          => "社員マスタ",
    "projects"           => "案件データ",
    "paid_leaves"        => "有給残日数",
    "offsets"            => "相殺繰越残高",
    "invoices"           => "請求・入金残高",
    "cash_flow_entries"  => "資金繰りデータ"
  }.freeze

  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(import_type: type) }

  # そのStepが実行可能か（前提Stepがすべて完了しているか、またはDBにデータがあるか）
  def self.step_available?(import_type)
    deps = STEP_DEPENDENCIES[import_type] || []
    deps.all? do |dep|
      step_completed?(dep) || model_has_data?(dep)
    end
  end

  # そのStepが完了済みか
  def self.step_completed?(import_type)
    where(import_type: import_type, status: "completed").exists?
  end

  # 対応モデルにデータがあるか（手動登録済みの場合）
  def self.model_has_data?(import_type)
    case import_type
    when "clients" then Client.exists?
    when "partners" then Partner.exists?
    when "employees" then Employee.exists?
    when "projects" then Project.exists?
    else false
    end
  end

  # 取込種別ラベル
  def import_type_label
    STEP_LABELS[import_type] || import_type
  end

  # ステータスラベル
  def status_label
    {
      "pending" => "待機中",
      "validating" => "検証中",
      "previewing" => "プレビュー中",
      "completed" => "完了",
      "failed" => "失敗"
    }[status] || status
  end

  # ステータスバッジクラス
  def status_badge_class
    case status
    when "pending" then "bg-gray-100 text-gray-800"
    when "validating", "previewing" then "bg-blue-100 text-blue-800"
    when "completed" then "bg-green-100 text-green-800"
    when "failed" then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def has_skipped_rows?
    skipped_rows.present? && skipped_rows.any?
  end

  def has_errors?
    error_rows.to_i > 0
  end
end
