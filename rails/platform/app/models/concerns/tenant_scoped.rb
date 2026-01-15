# frozen_string_literal: true

# Concern for multi-tenant data isolation
# All tenant-scoped models should include this concern
module TenantScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :tenant

    # Automatically scope all queries to current tenant
    default_scope { where(tenant_id: Current.tenant_id) if Current.tenant_id }

    # Auto-set tenant_id on create
    before_validation :set_tenant_id, on: :create

    # Ensure tenant_id is always present
    validates :tenant_id, presence: true
  end

  private

  def set_tenant_id
    self.tenant_id ||= Current.tenant_id
  end
end
