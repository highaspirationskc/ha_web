# frozen_string_literal: true

class ApplicationMessage
  def deliver
    return error_result("Subject is required") if subject.blank?
    return error_result("Message body is required") if body.blank?
    return error_result("At least one recipient is required") if recipients.empty?

    message = nil
    Message.transaction do
      message = Message.create!(
        author: author,
        parent: parent,
        subject: subject,
        message: body,
        reply_mode: reply_mode,
        support: support?
      )
      recipients.each { |r| message.recipients << r }
    end
    message.broadcast_to_recipients
    MessagesService::Result.new(success?: true, message: message)
  rescue ActiveRecord::RecordInvalid => e
    MessagesService::Result.new(success?: false, error: e.message)
  end

  def author    = nil
  def parent    = nil
  def reply_mode = :no_replies
  def support?  = false

  private

  def error_result(msg)
    MessagesService::Result.new(success?: false, error: msg)
  end
end
