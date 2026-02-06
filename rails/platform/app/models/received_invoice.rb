# frozen_string_literal: true

class ReceivedInvoice < ApplicationRecord
  include Auditable

  # Constants
  STATUSES = %w[pending approved rejected].freeze
  STATUS_LABELS = {
    "pending" => "確認中",
    "approved" => "確認完了",
    "rejected" => "却下"
  }.freeze

  APPROVAL_TYPES = %w[accounting sales engineering].freeze
  APPROVAL_LABELS = {
    "accounting" => "経理",
    "sales" => "営業",
    "engineering" => "工務"
  }.freeze

  # Associations
  belongs_to :partner, optional: true
  belongs_to :client, optional: true
  belongs_to :uploaded_by, class_name: "Employee"
  belongs_to :approved_by, class_name: "Employee", optional: true  # 却下者用

  # 各部門の承認者
  belongs_to :accounting_approved_by, class_name: "Employee", optional: true
  belongs_to :sales_approved_by, class_name: "Employee", optional: true
  belongs_to :engineering_approved_by, class_name: "Employee", optional: true

  has_many_attached :attachments

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :vendor_must_be_present

  # Scopes
  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent, -> { order(created_at: :desc) }

  # 発行元の表示名
  def vendor_display_name
    partner&.name || client&.name || vendor_name || "不明"
  end

  def status_label
    STATUS_LABELS[status] || status
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  # 各承認状態
  def accounting_approved?
    accounting_approved_by_id.present?
  end

  def sales_approved?
    sales_approved_by_id.present?
  end

  def engineering_approved?
    engineering_approved_by_id.present?
  end

  # 全承認済み？
  def fully_approved?
    accounting_approved? && sales_approved? && engineering_approved?
  end

  # 承認数
  def approval_count
    count = 0
    count += 1 if accounting_approved?
    count += 1 if sales_approved?
    count += 1 if engineering_approved?
    count
  end

  # 承認処理
  def approve!(approver, approval_type)
    return false unless pending?
    return false unless APPROVAL_TYPES.include?(approval_type)

    case approval_type
    when "accounting"
      return false if accounting_approved?
      update!(accounting_approved_by: approver, accounting_approved_at: Time.current)
    when "sales"
      return false if sales_approved?
      update!(sales_approved_by: approver, sales_approved_at: Time.current)
    when "engineering"
      return false if engineering_approved?
      update!(engineering_approved_by: approver, engineering_approved_at: Time.current)
    end

    # 全承認完了したらステータス更新
    reload
    update!(status: "approved") if fully_approved?

    true
  end

  # 却下処理
  def reject!(approver, reason)
    return false unless pending?
    return false if reason.blank?

    update!(
      status: "rejected",
      approved_by: approver,
      approved_at: Time.current,
      rejection_reason: reason
    )
  end

  private

  def vendor_must_be_present
    if partner.blank? && client.blank? && vendor_name.blank?
      errors.add(:base, "発行元（協力会社・顧客・会社名のいずれか）を入力してください")
    end
  end
end
