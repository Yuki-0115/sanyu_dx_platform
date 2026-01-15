# frozen_string_literal: true

# Current attributes for request-scoped data
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant_id, :user

  def tenant
    Tenant.find_by(id: tenant_id) if tenant_id
  end
end
