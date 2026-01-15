# frozen_string_literal: true

# 通知機能を提供するconcern
# n8n webhookまたはLINE WORKS直接通知をトリガー
module Notifiable
  extend ActiveSupport::Concern

  included do
    after_create_commit :notify_created, if: :should_notify_on_create?
    after_update_commit :notify_updated, if: :should_notify_on_update?
  end

  class_methods do
    def notify_on_create(enabled = true)
      @notify_on_create = enabled
    end

    def notify_on_update(enabled = true)
      @notify_on_update = enabled
    end

    def notify_on_create?
      @notify_on_create || false
    end

    def notify_on_update?
      @notify_on_update || false
    end
  end

  private

  def should_notify_on_create?
    self.class.notify_on_create?
  end

  def should_notify_on_update?
    self.class.notify_on_update?
  end

  def notify_created
    NotificationJob.perform_later(
      event_type: "#{self.class.name.underscore}_created",
      record_type: self.class.name,
      record_id: id
    )
  end

  def notify_updated
    NotificationJob.perform_later(
      event_type: "#{self.class.name.underscore}_updated",
      record_type: self.class.name,
      record_id: id,
      changes: saved_changes.except("updated_at")
    )
  end
end
