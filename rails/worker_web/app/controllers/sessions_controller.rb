# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    worker = Worker.find_by(code: params[:code])

    if worker && worker.authenticate_with_password(params[:password])
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
end
