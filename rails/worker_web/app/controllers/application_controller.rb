# frozen_string_literal: true

class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :require_login
  before_action :set_current_context

  helper_method :current_worker, :logged_in?

  private

  def current_worker
    @current_worker ||= Worker.find_by(id: session[:worker_id]) if session[:worker_id]
  end

  def logged_in?
    current_worker.present?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "ログインしてください"
    end
  end

  def set_current_context
    return unless current_worker

    Current.user = current_worker
  end
end
