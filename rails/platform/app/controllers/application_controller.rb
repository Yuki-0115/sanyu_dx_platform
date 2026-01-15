# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_employee!
  before_action :set_current_tenant

  private

  def set_current_tenant
    return unless current_employee

    Current.tenant_id = current_employee.tenant_id
    Current.user = current_employee
  end

  # Override Devise method to redirect after login
  def after_sign_in_path_for(_resource)
    root_path
  end

  # Override Devise method to redirect after logout
  def after_sign_out_path_for(_resource_or_scope)
    new_employee_session_path
  end
end
