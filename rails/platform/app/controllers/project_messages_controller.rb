# frozen_string_literal: true

class ProjectMessagesController < ApplicationController
  include ProjectScoped

  authorize_with :projects

  def index
    @messages = @project.project_messages.recent.includes(:employee)
    @message = @project.project_messages.build
  end

  def create
    @message = @project.project_messages.build(message_params)
    @message.employee = current_employee

    if @message.save
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

  private

  def message_params
    params.require(:project_message).permit(:content)
  end
end
