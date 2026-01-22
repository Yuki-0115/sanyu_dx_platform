# frozen_string_literal: true

class EstimatesController < ApplicationController
  authorize_with :estimates
  before_action :set_project
  before_action :set_estimate, only: %i[show edit update destroy approve pdf]

  def index
    @estimates = @project.estimates.order(created_at: :desc)
  end

  def show
    @tab = params[:tab] || "cover"
  end

  def new
    @estimate = @project.estimates.build(
      created_by: current_employee,
      estimate_date: Date.current,
      valid_until: Date.current + 90.days,
      recipient: @project.client&.name.to_s + " 御中",
      subject: @project.name,
      location: @project.location,
      period_start: @project.scheduled_start_date,
      period_end: @project.scheduled_end_date,
      person_in_charge: current_employee&.name,
      special_note: "別紙、工事見積確認書及び見積条件書による",
      payment_terms: "出来高現金払 現金100％"
    )
    build_default_confirmations
    @tab = params[:tab] || "cover"
  end

  def create
    @estimate = @project.estimates.build(estimate_params)
    @estimate.created_by = current_employee

    if @estimate.save
      redirect_to project_estimate_path(@project, @estimate), notice: "見積書を作成しました"
    else
      build_default_confirmations if @estimate.estimate_confirmations.empty?
      @tab = params[:tab] || "cover"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_default_confirmations if @estimate.estimate_confirmations.empty?
    @tab = params[:tab] || "cover"
  end

  def update
    if @estimate.update(estimate_params)
      redirect_to project_estimate_path(@project, @estimate, tab: params[:tab]),
                  notice: "見積書を更新しました"
    else
      @tab = params[:tab] || "cover"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @estimate.destroy
    redirect_to project_estimates_path(@project), notice: "見積書を削除しました"
  end

  def approve
    if @estimate.status == "submitted"
      @estimate.update!(status: "approved")
      redirect_to project_estimate_path(@project, @estimate), notice: "見積書を承認しました"
    else
      redirect_to project_estimate_path(@project, @estimate), alert: "提出済みの見積書のみ承認できます"
    end
  end

  def pdf
    # PDF出力（後で実装）
    respond_to do |format|
      format.pdf do
        # render pdf: "estimate_#{@estimate.estimate_number}"
        redirect_to project_estimate_path(@project, @estimate), alert: "PDF出力は準備中です"
      end
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_estimate
    @estimate = @project.estimates.find(params[:id])
  end

  def estimate_params
    params.require(:estimate).permit(
      :estimate_date, :valid_until, :recipient, :subject, :location,
      :period_start, :period_end, :validity_period,
      :payment_terms, :waste_disposal_note, :special_note,
      :person_in_charge, :overhead_rate, :welfare_rate,
      :adjustment, :conditions, :status, :notes,
      estimate_items_attributes: [
        :id, :name, :specification, :quantity, :unit, :unit_price, :note,
        :budget_quantity, :budget_unit, :budget_unit_price, :construction_days,
        :sort_order, :category, :_destroy,
        estimate_item_costs_attributes: [
          :id, :cost_name, :quantity, :unit, :unit_price,
          :calculation_type, :formula_params, :note, :sort_order, :_destroy
        ]
      ],
      estimate_confirmations_attributes: [
        :id, :item_category, :item_name, :responsibility, :note, :sort_order, :_destroy
      ]
    )
  end

  def build_default_confirmations
    return if @estimate.estimate_confirmations.any?

    sort_order = 0

    CONFIRMATION_ITEMS.each do |category, items|
      items.each do |item_name|
        @estimate.estimate_confirmations.build(
          item_category: category,
          item_name: item_name,
          sort_order: sort_order
        )
        sort_order += 1
      end
    end

    CONFIRMATION_SPECIAL_ITEMS.each do |item_name|
      @estimate.estimate_confirmations.build(
        item_category: "特記事項",
        item_name: item_name,
        sort_order: sort_order
      )
      sort_order += 1
    end
  end
end
