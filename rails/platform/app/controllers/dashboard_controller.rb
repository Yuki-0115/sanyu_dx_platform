# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @employee = current_employee
  end
end
