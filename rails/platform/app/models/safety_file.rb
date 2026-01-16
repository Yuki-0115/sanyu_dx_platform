# frozen_string_literal: true

class SafetyFile < ApplicationRecord
  include TenantScoped

  # Associations
  belongs_to :safety_folder, counter_cache: :files_count
  belongs_to :uploaded_by, class_name: "Employee", optional: true

  # ファイル添付（複数可）
  has_many_attached :attachments

  # Validations
  validates :name, presence: true

  # Callbacks
  after_save :update_folder_count
  after_destroy :update_folder_count

  private

  def update_folder_count
    safety_folder&.update_files_count!
  end
end
