# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    worker = Worker.find_by(code: params[:code])

    if worker && authenticate_worker(worker)
      session[:worker_id] = worker.id
      redirect_to root_path, notice: "ログインしました"
    else
      flash.now[:alert] = "社員番号またはパスワードが正しくありません"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:worker_id)
    redirect_to login_path, notice: "ログアウトしました"
  end

  private

  def authenticate_worker(worker)
    # 簡易認証: 社員コード + 生年月日4桁（MMDD）
    # パスワードが設定されている場合はそちらを優先
    if worker.respond_to?(:authenticate) && worker.password_digest.present?
      worker.authenticate(params[:password])
    else
      # 生年月日での簡易認証
      params[:password] == worker.birth_date&.strftime("%m%d")
    end
  end
end
