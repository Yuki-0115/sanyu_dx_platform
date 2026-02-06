# frozen_string_literal: true

class CostUnitsController < ApplicationController
  authorize_with :master

  before_action :set_unit, only: %i[edit update destroy]

  def index
    @units = CostUnit.ordered
  end

  def new
    @unit = CostUnit.new
  end

  def create
    @unit = CostUnit.new(unit_params)

    if @unit.save
      redirect_to cost_units_path, notice: "単位を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params)
      redirect_to cost_units_path, notice: "単位を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @unit.destroy
    redirect_to cost_units_path, notice: "単位を削除しました"
  end

  # 初期データ投入
  def seed_defaults
    CostUnit::DEFAULT_UNITS.each_with_index do |name, idx|
      CostUnit.find_or_create_by!(name: name) do |u|
        u.sort_order = idx
      end
    end
    redirect_to cost_units_path, notice: "デフォルトの単位を追加しました"
  end

  private

  def set_unit
    @unit = CostUnit.find(params[:id])
  end

  def unit_params
    params.require(:cost_unit).permit(:name, :sort_order)
  end
end
