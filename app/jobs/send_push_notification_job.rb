class SendPushNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    recipients = message.recipients.where.not(id: message.author_id)
    return if recipients.empty?

    title = build_title(message)
    body = build_body(message)
    data = build_data(message)

    service = FirebaseNotificationService.new
    service.send_to_users(recipients, title: title, body: body, data: data)
  rescue FirebaseNotificationService::NotificationError => e
    Rails.logger.error("Push notification failed for message #{message_id}: #{e.message}")
  end

  private

  def build_title(message)
    "#{message.author.first_name || 'Someone'} sent you a message"
  end

  def build_body(message)
    preview = message.message.truncate(100)
    "#{message.subject}: #{preview}"
  end

  def build_data(message)
    {
      message_id: message.id,
      thread_id: message.thread_root.id,
      type: "new_message"
    }
  end
end
