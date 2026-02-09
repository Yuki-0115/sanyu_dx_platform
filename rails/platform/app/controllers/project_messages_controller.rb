# frozen_string_literal: true

class ProjectMessagesController < ApplicationController
  include ProjectScoped

  authorize_with :projects

  before_action :set_message, only: [:destroy]

  def index
    @messages = @project.project_messages.recent.includes(:employee)
    @message = @project.project_messages.build
  end

  def create
    @message = @project.project_messages.build(message_params)
    @message.employee = current_employee

    if @message.save
      # メンションされた社員にLINE WORKS通知を送信
      send_mention_notifications(@message)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to project_path(@project), notice: "メッセージを送信しました" }
      end
    else
      @messages = @project.project_messages.recent.includes(:employee)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("chat-form", partial: "form", locals: { project: @project, message: @message }) }
        format.html { redirect_to project_path(@project), alert: "メッセージを送信できませんでした" }
      end
    end
  end

  # メンション既読マーク
  def mark_mentions_read
    current_employee.update(last_mention_read_at: Time.current)
    head :ok
  end

  def destroy
    # 自分のメッセージのみ削除可能（管理者は全て削除可能）
    unless @message.employee == current_employee || current_employee.admin?
      return redirect_to project_path(@project), alert: "削除権限がありません"
    end

    @message.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@message) }
      format.html { redirect_to project_path(@project), notice: "メッセージを削除しました" }
    end
  end

  private

  def set_message
    @message = @project.project_messages.find(params[:id])
  end

  def message_params
    params.require(:project_message).permit(:content)
  end

  def send_mention_notifications(message)
    return if message.mentioned_user_ids.blank?

    message.mentioned_employees.find_each do |employee|
      next if employee == current_employee  # 自分へのメンションは通知しない

      LineWorksNotifier.chat_mention(message, employee)
    end
  end
end
