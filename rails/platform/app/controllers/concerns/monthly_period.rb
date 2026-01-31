# frozen_string_literal: true

# 月次レポート系コントローラーで共通の期間設定ロジック
module MonthlyPeriod
  extend ActiveSupport::Concern

  included do
    before_action :set_period
  end

  private

  def set_period
    @year = params[:year].present? ? params[:year].to_i : Date.current.year
    @month = params[:month].present? ? params[:month].to_i : Date.current.month

    return if valid_period?

    redirect_to default_period_path, alert: "無効な年月が指定されました"
  end

  def valid_period?
    @year >= 2000 && @year <= 2100 && @month >= 1 && @month <= 12
  end

  # サブクラスでオーバーライド可能
  def default_period_path
    root_path
  end

  # 前月の年月を取得
  def previous_period
    if @month == 1
      [@year - 1, 12]
    else
      [@year, @month - 1]
    end
  end

  # 翌月の年月を取得
  def next_period
    if @month == 12
      [@year + 1, 1]
    else
      [@year, @month + 1]
    end
  end

  # 期間ラベル
  def period_label
    "#{@year}年#{@month}月"
  end
end
