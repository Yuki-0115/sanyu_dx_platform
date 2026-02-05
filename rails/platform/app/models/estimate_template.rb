# frozen_string_literal: true

class EstimateTemplate < ApplicationRecord
  TEMPLATE_TYPES = %w[condition confirmation].freeze

  belongs_to :employee, optional: true

  validates :template_type, presence: true, inclusion: { in: TEMPLATE_TYPES }
  validates :name, presence: true
  validates :content, presence: true

  scope :conditions, -> { where(template_type: "condition") }
  scope :confirmations, -> { where(template_type: "confirmation") }
  scope :shared, -> { where(is_shared: true) }
  scope :personal, -> { where(is_shared: false) }
  scope :for_employee, ->(employee) { where(employee_id: employee.id) }
  scope :available_for, ->(employee) { where(is_shared: true).or(where(employee_id: employee.id)) }
  scope :ordered, -> { order(sort_order: :asc, name: :asc) }

  # 条件書テンプレート
  def self.condition_templates_for(employee)
    conditions.available_for(employee).ordered
  end

  # 確認書テンプレート
  def self.confirmation_templates_for(employee)
    confirmations.available_for(employee).ordered
  end

  def shared?
    is_shared
  end

  def personal?
    !is_shared
  end

  def owned_by?(employee)
    employee_id == employee.id
  end

  def editable_by?(employee)
    return true if employee.role.in?(%w[admin management])
    owned_by?(employee)
  end
end
