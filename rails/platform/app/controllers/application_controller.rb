# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authorizable

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_employee!
  before_action :set_current_user

  private

  def set_current_user
    Current.user = current_employee
  end

  # 全角数字・カンマを半角に変換して数値化
  # 金額入力時に全角でも受け付けるため
  def normalize_number(value)
    return 0 if value.blank?

    value.to_s
         .tr("０-９", "0-9")  # 全角数字→半角
         .tr("，", ",")       # 全角カンマ→半角
         .gsub(",", "")       # カンマ削除
         .to_i
  end

  # Override Devise method to redirect after login
  def after_sign_in_path_for(_resource)
    root_path
  end

  # Override Devise method to redirect after logout
  def after_sign_out_path_for(_resource_or_scope)
    new_employee_session_path
  end
end
