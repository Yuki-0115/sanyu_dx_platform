# frozen_string_literal: true

module Authorizable
  extend ActiveSupport::Concern

  class NotAuthorizedError < StandardError; end

  included do
    rescue_from NotAuthorizedError, with: :handle_not_authorized
  end

  class_methods do
    # Usage: authorize_with :projects
    # Equivalent to: before_action { authorize_feature!(:projects) }
    def authorize_with(feature)
      before_action { authorize_feature!(feature) }
    end
  end

  private

  # Check if current employee can access a feature
  def authorize_feature!(feature)
    return if current_employee&.can_access?(feature)

    raise NotAuthorizedError, "この機能へのアクセス権限がありません"
  end

  # Check if current employee has a specific role
  def require_role!(*roles)
    return if roles.any? { |role| current_employee&.role == role.to_s }

    raise NotAuthorizedError, "この機能へのアクセス権限がありません"
  end

  # Check if current employee is admin
  def require_admin!
    require_role!(:admin)
  end

  # Check if current employee is management or admin
  def require_management!
    require_role!(:admin, :management)
  end

  def handle_not_authorized
    respond_to do |format|
      format.html do
        flash[:alert] = "この機能へのアクセス権限がありません"
        redirect_to root_path
      end
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
    end
  end
end
