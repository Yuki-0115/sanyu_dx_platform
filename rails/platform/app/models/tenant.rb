# frozen_string_literal: true

class Tenant < ApplicationRecord
  # Associations
  has_many :clients, dependent: :destroy
  has_many :partners, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :projects, dependent: :destroy
  has_many :budgets, dependent: :destroy
  has_many :daily_reports, dependent: :destroy
  has_many :attendances, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :offsets, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
