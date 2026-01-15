# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authorize_dashboard_access

  def index
    @employee = current_employee
  end

  private

  def authorize_dashboard_access
    authorize_feature!(:dashboard)
  end
end
