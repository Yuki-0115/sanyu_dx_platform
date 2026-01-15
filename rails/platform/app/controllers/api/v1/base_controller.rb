# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_request

      private

      def authenticate_api_request
        api_key = request.headers["X-API-Key"]
        return if api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, api_secret_key)

        render json: { error: "Unauthorized" }, status: :unauthorized
      end

      def api_secret_key
        ENV.fetch("N8N_API_KEY", "development_api_key_change_in_production")
      end

      def set_tenant_from_code
        tenant_code = params[:tenant_code] || request.headers["X-Tenant-Code"]
        @tenant = Tenant.find_by(code: tenant_code)
        unless @tenant
          render json: { error: "Tenant not found" }, status: :not_found
          return false
        end
        Current.tenant_id = @tenant.id
        true
      end
    end
  end
end
