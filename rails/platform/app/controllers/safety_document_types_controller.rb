# frozen_string_literal: true

class SafetyDocumentTypesController < ApplicationController
  authorize_with :master
  before_action :set_safety_document_type, only: %i[edit update destroy toggle_active move]

  def index
    @safety_document_types = SafetyDocumentType.ordered
  end

  def new
    @safety_document_type = SafetyDocumentType.new
    @safety_document_type.position = SafetyDocumentType.maximum(:position).to_i + 1
  end

  def create
    @safety_document_type = SafetyDocumentType.new(safety_document_type_params)

    if @safety_document_type.save
      redirect_to safety_document_types_path, notice: "書類種類を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @safety_document_type.update(safety_document_type_params)
      redirect_to safety_document_types_path, notice: "書類種類を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @safety_document_type.destroy
    redirect_to safety_document_types_path, notice: "書類種類を削除しました"
  end

  def toggle_active
    @safety_document_type.update(active: !@safety_document_type.active)
    redirect_to safety_document_types_path, notice: "ステータスを変更しました"
  end

  def move
    direction = params[:direction]
    current_position = @safety_document_type.position

    if direction == "up" && current_position > 1
      swap_with = SafetyDocumentType.find_by(position: current_position - 1)
      if swap_with
        swap_with.update(position: current_position)
        @safety_document_type.update(position: current_position - 1)
      end
    elsif direction == "down"
      swap_with = SafetyDocumentType.find_by(position: current_position + 1)
      if swap_with
        swap_with.update(position: current_position)
        @safety_document_type.update(position: current_position + 1)
      end
    end

    redirect_to safety_document_types_path
  end

  def seed_defaults
    SafetyDocumentType.seed_defaults
    redirect_to safety_document_types_path, notice: "デフォルトの書類種類を登録しました"
  end

  private

  def set_safety_document_type
    @safety_document_type = SafetyDocumentType.find(params[:id])
  end

  def safety_document_type_params
    params.require(:safety_document_type).permit(:name, :description, :position, :active)
  end
end
