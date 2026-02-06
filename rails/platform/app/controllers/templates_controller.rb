# frozen_string_literal: true

class TemplatesController < ApplicationController
  authorize_with :master

  def index
    @estimate_templates_count = EstimateTemplate.available_for(current_employee).count
    @estimate_item_templates_count = EstimateItemTemplate.available_for(current_employee).count
    @cost_breakdown_templates_count = CostBreakdownTemplate.available_for(current_employee).count
    @cost_units_count = CostUnit.count
  end
end
