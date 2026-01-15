# frozen_string_literal: true

class AuditLog < ApplicationRecord
  # Note: AuditLog does NOT include TenantScoped to allow unscoped creation
  # but still stores tenant_id for filtering

  # Associations
  belongs_to :tenant
  belongs_to :user, class_name: "Employee", optional: true

  # Validations
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true
  validates :action, presence: true, inclusion: { in: %w[create update delete] }

  # Scopes
  scope :for_record, ->(type, id) { where(auditable_type: type, auditable_id: id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.for_tenant(tenant_id)
    where(tenant_id: tenant_id)
  end
end
