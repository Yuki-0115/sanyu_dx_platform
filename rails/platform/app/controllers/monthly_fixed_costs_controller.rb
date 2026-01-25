# frozen_string_literal: true

class MonthlyFixedCostsController < ApplicationController
  before_action :set_period
  before_action :set_monthly_fixed_cost, only: [:edit, :update, :destroy]

  def index
    @fixed_costs = MonthlyFixedCost.for_month(@year, @month).ordered
    @grouped_costs = @fixed_costs.group_by(&:category)
    @total = MonthlyFixedCost.total_for_month(@year, @month)
  end

  def new
    @fixed_cost = MonthlyFixedCost.new(year: @year, month: @month)
  end

  def create
    @fixed_cost = MonthlyFixedCost.new(fixed_cost_params)
    @fixed_cost.year = @year
    @fixed_cost.month = @month

    if @fixed_cost.save
      redirect_to monthly_fixed_costs_path(year: @year, month: @month), notice: "固定費を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @fixed_cost.update(fixed_cost_params)
      redirect_to monthly_fixed_costs_path(year: @year, month: @month), notice: "固定費を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @fixed_cost.destroy
    redirect_to monthly_fixed_costs_path(year: @year, month: @month), notice: "固定費を削除しました"
  end

  def copy_from_previous
    MonthlyFixedCost.copy_from_previous_month(@year, @month)
    redirect_to monthly_fixed_costs_path(year: @year, month: @month), notice: "前月の固定費をコピーしました"
  rescue => e
    redirect_to monthly_fixed_costs_path(year: @year, month: @month), alert: "コピーに失敗しました: #{e.message}"
  end

  private

  def set_period
    @year = params[:year].to_i
    @month = params[:month].to_i

    if @year < 2000 || @month < 1 || @month > 12
      redirect_to monthly_fixed_costs_path(year: Date.current.year, month: Date.current.month)
    end
  end

  def set_monthly_fixed_cost
    @fixed_cost = MonthlyFixedCost.find(params[:id])
  end

  def fixed_cost_params
    params.require(:monthly_fixed_cost).permit(:name, :category, :amount, :description)
  end
end
