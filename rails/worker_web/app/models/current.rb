# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :tenant_id, :user
end
