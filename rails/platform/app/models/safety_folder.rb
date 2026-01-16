# frozen_string_literal: true

class SafetyFolder < ApplicationRecord
  include TenantScoped

  # Associations
  belongs_to :project, optional: true
  has_many :safety_files, dependent: :destroy

  # Validations
  validates :name, presence: true

  # Scopes
  scope :for_project, ->(project_id) { where(project_id: project_id) }
  scope :general, -> { where(project_id: nil) }
  scope :with_files, -> { where("files_count > 0") }

  # Counter cache
  def update_files_count!
    update_column(:files_count, safety_files.count)
  end
end
