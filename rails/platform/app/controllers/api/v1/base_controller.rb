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
    end
  end
end
