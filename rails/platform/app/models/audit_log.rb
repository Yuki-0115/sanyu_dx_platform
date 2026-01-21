# frozen_string_literal: true

class AuditLog < ApplicationRecord
  # Associations
  belongs_to :user, class_name: "Employee", optional: true

  # Validations
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true
  validates :action, presence: true, inclusion: { in: %w[create update delete] }

  # Scopes
  scope :for_record, ->(type, id) { where(auditable_type: type, auditable_id: id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(created_at: :desc) }
end
