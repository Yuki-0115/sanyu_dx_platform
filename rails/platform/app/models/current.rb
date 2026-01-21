# frozen_string_literal: true

# Current attributes for request-scoped data
class Current < ActiveSupport::CurrentAttributes
  attribute :user
end
