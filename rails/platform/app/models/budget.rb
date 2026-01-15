class Budget < ApplicationRecord
  belongs_to :tenant
  belongs_to :project
end
