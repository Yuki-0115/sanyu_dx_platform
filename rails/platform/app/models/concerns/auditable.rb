# frozen_string_literal: true

# Concern for audit logging
# Records who changed what and when
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create  :log_create
    after_update  :log_update
    after_destroy :log_destroy
  end

  private

  def log_create
    create_audit_log("create", nil, attributes)
  end

  def log_update
    return if saved_changes.except("updated_at").empty?

    create_audit_log("update", saved_changes.except("updated_at"), nil)
  end

  def log_destroy
    create_audit_log("delete", attributes, nil)
  end

  def create_audit_log(action, changed_data, _new_data)
    return unless Current.tenant_id

    AuditLog.unscoped.create!(
      tenant_id: tenant_id_for_audit,
      user_id: Current.user&.id,
      auditable_type: self.class.name,
      auditable_id: id,
      action: action,
      changed_data: changed_data
    )
  rescue StandardError => e
    Rails.logger.error("Failed to create audit log: #{e.message}")
  end

  def tenant_id_for_audit
    respond_to?(:tenant_id) ? tenant_id : Current.tenant_id
  end
end
