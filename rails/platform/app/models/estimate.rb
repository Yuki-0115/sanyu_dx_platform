# frozen_string_literal: true

class Estimate < ApplicationRecord
  include Auditable

  # Constants
  STATUSES = %w[draft submitted approved rejected].freeze

  # 単位選択肢
  UNIT_OPTIONS = %w[m2 m3 m 式 人工 t kg 台 日 本 枚 個 箇所].freeze

  # 確認書の固定項目（カテゴリー => 項目名の配列）
  CONFIRMATION_ITEMS = {
    "材料費" => ["As合材", "RC-40 RM-25"],
    "施工管理" => ["写真管理", "出来形管理", "品質管理"],
    "安全費" => ["保安要員", "保安施設"],
    "仮設経費（左）" => [
      "看板・標識類", "保安関係費", "電気引込費", "土捨場代", "丁張材料"
    ],
    "仮設経費（右）" => [
      "基本測量", "施工測量", "測量機器", "仮設道路", "工事用電気",
      "工事用水道", "工事用借地料", "重機仮置場", "現場事務所",
      "宿舎", "倉庫", "電気 水道 ガス", "借地料"
    ],
    "その他" => ["労災保険料", "建退協証紙代"]
  }.freeze

  # 確認書の特記事項項目
  CONFIRMATION_SPECIAL_ITEMS = [
    "職員", "家屋調査", "施工前調査", "工期延期", "回送費", "施工回数", "新規工種", "数量増減",
    "工法・構造の変更", "軟弱路床", "軟弱路盤", "その他"
  ].freeze

  # 条件書テンプレート
  CONDITION_TEMPLATES = {
    "舗装工事_標準" => <<~TEXT.strip,
      ・産業廃棄物 運搬処分は別途
      ・昼間施工 08:00～17:00
      ・舗装機械 小物機械 含む
      ・重機 労務回送 1往復 含みます
      ・路床 路盤 軟弱な場合は別途協議願います
      ・勾配1.5％以上確保願います
      ・舗装版切断 含みません
      ・安全費 ガードマンは含みません
      ・掘削残土運搬処分 含みません
    TEXT
    "地盤改良_標準" => <<~TEXT.strip
      ・産業廃棄物 運搬処分は別途
      ・昼間施工 08:00～17:00
      ・地盤改良機械 含む
      ・重機 労務回送 1往復 含みます
      ・軟弱地盤の場合は別途協議願います
    TEXT
  }.freeze

  # 原価項目のデフォルト（計算モーダル用）
  DEFAULT_COST_ITEMS = [
    { cost_name: "セメント", unit: "t", unit_price: 15000 },
    { cost_name: "再密13", unit: "", unit_price: 11000 },
    { cost_name: "PK-3", unit: "", unit_price: 130 },
    { cost_name: "02BH", unit: "日", unit_price: 8000 },
    { cost_name: "労務", unit: "人工", unit_price: 18000 },
    { cost_name: "高速代", unit: "式", unit_price: 15000 }
  ].freeze

  # Associations
  belongs_to :project
  belongs_to :created_by, class_name: "Employee", optional: true

  has_many :estimate_categories, dependent: :destroy
  has_many :estimate_items, dependent: :destroy
  has_many :estimate_confirmations, dependent: :destroy

  accepts_nested_attributes_for :estimate_categories, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["name"].blank? }
  accepts_nested_attributes_for :estimate_items, allow_destroy: true,
                                reject_if: ->(attrs) { attrs["name"].blank? }
  accepts_nested_attributes_for :estimate_confirmations, allow_destroy: true

  # Validations
  validates :status, inclusion: { in: STATUSES }
  validates :estimate_number, uniqueness: true, allow_blank: true

  # Defaults
  attribute :status, :string, default: "draft"
  attribute :overhead_rate, :decimal, default: 4.0
  attribute :welfare_rate, :decimal, default: 3.0
  attribute :adjustment, :integer, default: 0
  attribute :validity_period, :string, default: "3ヵ月"
  attribute :version, :integer, default: 1

  # Callbacks
  before_create :generate_estimate_number
  after_save :update_project_estimated_amount, if: :saved_change_to_status?

  # Scopes
  scope :approved, -> { where(status: "approved") }

  # 見積金額の小計（内訳明細の合計）
  def direct_cost
    if estimate_categories.any?
      estimate_categories.sum(&:direct_cost)
    else
      estimate_items.sum(:amount) || 0
    end
  end

  # 諸経費（工種別の合計）
  def overhead_cost
    if estimate_categories.any?
      estimate_categories.sum(&:overhead_cost)
    else
      (direct_cost * (overhead_rate || 0) / 100).round(0)
    end
  end

  # 法定福利費（工種別の合計）
  def welfare_cost
    if estimate_categories.any?
      estimate_categories.sum(&:welfare_cost)
    else
      (direct_cost * (welfare_rate || 0) / 100).round(0)
    end
  end

  # 見積合計（税抜）
  def subtotal
    direct_cost + overhead_cost + welfare_cost + (adjustment || 0)
  end

  # 工種ごとの小計合計（直接工事費+諸経費+法定福利費）
  def categories_subtotal
    estimate_categories.sum(&:subtotal)
  end

  # 消費税
  def tax_amount
    (subtotal * 0.1).round(0)
  end

  # 見積合計（税込）
  def total_amount
    subtotal + tax_amount
  end

  # 予算小計（工種がある場合は工種に紐付いた項目のみ）
  def budget_total
    if estimate_categories.any?
      estimate_items.where.not(estimate_category_id: nil).sum(:budget_amount) || 0
    else
      estimate_items.sum(:budget_amount) || 0
    end
  end

  # 粗利
  def gross_profit
    subtotal - budget_total
  end

  # 粗利率
  def profit_rate
    return 0 if subtotal.zero?
    (gross_profit.to_f / subtotal * 100).round(1)
  end

  def approved?
    status == "approved"
  end

  def can_import_to_budget?
    approved? || status == "submitted"
  end

  private

  def generate_estimate_number
    return if estimate_number.present?

    prefix = "EST"
    date_part = Date.current.strftime("%Y%m")
    seq = Estimate.where("estimate_number LIKE ?", "#{prefix}#{date_part}%").count + 1
    self.estimate_number = "#{prefix}#{date_part}#{seq.to_s.rjust(3, '0')}"
  end

  # 承認時に案件の見積金額を更新
  def update_project_estimated_amount
    return unless status == "approved"

    project.update!(estimated_amount: total_amount)
  end
end
