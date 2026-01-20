# frozen_string_literal: true

class OffsetsController < ApplicationController
  authorize_with :offsets
  before_action :set_offset, only: %i[show edit update confirm]

  def index
    @year_month = params[:year_month] || Date.current.strftime("%Y-%m")
    @offsets = Offset.includes(:partner).for_month(@year_month).order("partners.name")
    @partners = Partner.where(has_temporary_employees: true).order(:name)
  end

  def show; end

  def new
    @offset = Offset.new(year_month: params[:year_month] || Date.current.strftime("%Y-%m"))
    @partners = Partner.where(has_temporary_employees: true).order(:name)
  end

  def edit
    @partners = Partner.where(has_temporary_employees: true).order(:name)
  end

  def create
    @offset = Offset.new(offset_params)

    if @offset.save
      redirect_to @offset, notice: "相殺データを作成しました"
    else
      @partners = Partner.where(has_temporary_employees: true).order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @offset.update(offset_params)
      redirect_to @offset, notice: "相殺データを更新しました"
    else
      @partners = Partner.where(has_temporary_employees: true).order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def confirm
    if @offset.status == "draft"
      @offset.confirm!(current_employee)
      redirect_to @offset, notice: "相殺データを確定しました"
    else
      redirect_to @offset, alert: "既に確定済みです"
    end
  end

  private

  def set_offset
    @offset = Offset.find(params[:id])
  end

  def offset_params
    params.require(:offset).permit(
      :partner_id, :year_month, :total_salary, :social_insurance,
      :revenue_amount
    )
  end
end
