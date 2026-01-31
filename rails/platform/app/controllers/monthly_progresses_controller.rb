# frozen_string_literal: true

# 月次出来高入力
class MonthlyProgressesController < ApplicationController
  include ProjectScoped

  skip_before_action :set_project, except: [:update_for_project]
  before_action :set_period, except: [:update_for_project]

  # 月次出来高一覧（一括入力）
  def index
    # 進行中の案件（施工中 or 完工）を取得
    @projects = Project.where(status: %w[in_progress completed])
                       .includes(:client)
                       .order(:scheduled_start_date)

    # 既存の出来高データを取得
    @progresses = ProjectMonthlyProgress.for_month(@year, @month)
                                        .index_by(&:project_id)

    # 前月の出来高データ
    prev_date = Date.new(@year, @month, 1).prev_month
    @prev_progresses = ProjectMonthlyProgress.for_month(prev_date.year, prev_date.month)
                                             .index_by(&:project_id)

    # 累計請求済み金額
    end_date = Date.new(@year, @month, 1).end_of_month
    @total_invoiced = Invoice.where("issued_date <= ?", end_date)
                             .where(status: %w[issued paid])
                             .group(:project_id)
                             .sum(:amount)
  end

  # 一括保存
  def bulk_update
    success_count = 0
    errors = []

    params[:progresses]&.each do |project_id, data|
      amount = normalize_number(data[:progress_amount])
      next if amount.nil? || amount < 0

      progress = ProjectMonthlyProgress.find_or_initialize_by(
        project_id: project_id,
        year: @year,
        month: @month
      )
      progress.progress_amount = amount
      progress.note = data[:note]

      if progress.save
        success_count += 1
      else
        project = Project.find_by(id: project_id)
        errors << "#{project&.name}: #{progress.errors.full_messages.join(', ')}"
      end
    end

    if errors.any?
      redirect_to monthly_progresses_path(year: @year, month: @month),
                  alert: "一部保存に失敗: #{errors.join('; ')}"
    elsif success_count > 0
      redirect_to monthly_progresses_path(year: @year, month: @month),
                  notice: "#{success_count}件の出来高を保存しました"
    else
      redirect_to monthly_progresses_path(year: @year, month: @month),
                  alert: "保存するデータがありません"
    end
  end

  # 前月の出来高をコピー
  def copy_from_previous
    prev_date = Date.new(@year, @month, 1).prev_month
    prev_progresses = ProjectMonthlyProgress.for_month(prev_date.year, prev_date.month)

    if prev_progresses.empty?
      redirect_to monthly_progresses_path(year: @year, month: @month),
                  alert: "前月のデータがありません"
      return
    end

    copied = 0
    prev_progresses.each do |prev|
      next if ProjectMonthlyProgress.exists?(project_id: prev.project_id, year: @year, month: @month)

      ProjectMonthlyProgress.create!(
        project_id: prev.project_id,
        year: @year,
        month: @month,
        progress_amount: prev.progress_amount,
        note: "前月からコピー"
      )
      copied += 1
    end

    if copied > 0
      redirect_to monthly_progresses_path(year: @year, month: @month),
                  notice: "#{copied}件を前月からコピーしました"
    else
      redirect_to monthly_progresses_path(year: @year, month: @month),
                  alert: "コピーするデータがありません（既に登録済み）"
    end
  end

  # 案件詳細からの出来高更新
  def update_for_project
    year = params[:year].to_i
    month = params[:month].to_i

    if year < 2000 || month < 1 || month > 12
      redirect_to project_path(@project), alert: "無効な年月です"
      return
    end

    progress_amount = normalize_number(params[:progress_amount])

    progress = ProjectMonthlyProgress.find_or_initialize_by(
      project_id: @project.id,
      year: year,
      month: month
    )

    progress.progress_amount = progress_amount
    progress.note = params[:note]

    if progress.save
      redirect_to project_path(@project), notice: "#{year}年#{month}月の出来高を保存しました"
    else
      redirect_to project_path(@project), alert: "保存に失敗しました: #{progress.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_period
    @year = params[:year].to_i
    @month = params[:month].to_i

    if @year < 2000 || @month < 1 || @month > 12
      redirect_to monthly_progresses_path(year: Date.current.year, month: Date.current.month)
    end
  end
end
