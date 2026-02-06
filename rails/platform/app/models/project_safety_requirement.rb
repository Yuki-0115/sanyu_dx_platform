# frozen_string_literal: true

class ProjectSafetyRequirement < ApplicationRecord
  belongs_to :project
  belongs_to :safety_document_type

  validates :project_id, uniqueness: { scope: :safety_document_type_id }

  scope :ordered, -> { joins(:safety_document_type).order("safety_document_types.position") }
end
