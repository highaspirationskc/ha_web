# frozen_string_literal: true

class MessagesController < AuthenticatedController
  before_action { require_navigation_access(:inbox) }
  before_action :set_message, only: [:show, :archive, :unarchive]
  before_action :authorize_view, only: [:show]
  before_action :authorize_recipient_action, only: [:archive, :unarchive]

  def index
    @messages = messages_service.inbox
  end

  def sent
    @messages = messages_service.sent
  end

  def archived
    @messages = messages_service.archived
  end

  def show
    thread_root = @message.thread_root

    # Get thread messages based on reply mode and user's role
    if thread_root.reply_to_all? || thread_root.author == current_user
      # Reply to all: everyone sees all messages
      # Or: author always sees all messages
      @thread_messages = thread_root.thread_messages.includes(:author, :recipients)
    else
      # Reply to sender only: recipients only see root + their own replies
      @thread_messages = [thread_root] + thread_root.replies
                          .includes(:author, :recipients)
                          .where(author: current_user)
                          .order(:created_at)
    end

    # Mark visible messages as read
    messages_service.mark_thread_read(message_id: @message.id)

    # For reply form - determine recipients based on thread root's reply_mode
    if thread_root.reply_to_all?
      # Reply to all thread participants (excluding current user)
      @reply_recipients = (@thread_messages.map(&:author) + @thread_messages.flat_map(&:recipients))
                          .uniq
                          .reject { |u| u == current_user }
    elsif current_user.can?(:reply_any, :messages)
      # Staff/admin can reply to anyone in the thread
      @reply_recipients = (@thread_messages.map(&:author) + @thread_messages.flat_map(&:recipients))
                          .uniq
                          .reject { |u| u == current_user }
    else
      # Reply only to the thread root author (unless it's the current user)
      @reply_recipients = thread_root.author == current_user ? [] : [thread_root.author]
    end
  end

  def new
    @message = Message.new
    @message.parent_id = params[:reply_to] if params[:reply_to]

    if @message.parent_id
      parent = Message.find(@message.parent_id)
      @message.subject = parent.subject.start_with?("Re:") ? parent.subject : "Re: #{parent.subject}"
    end

    recipients = messages_service.compose_recipients
    @messageable_users = recipients[:users]
    @group_recipients = recipients[:groups]
  end

  def archive
    result = messages_service.archive(message_id: @message.id)
    if result.success?
      redirect_to messages_path, notice: "Message archived"
    else
      redirect_to messages_path, alert: result.error
    end
  end

  def unarchive
    result = messages_service.unarchive(message_id: @message.id)
    if result.success?
      redirect_to archived_messages_path, notice: "Message moved to inbox"
    else
      redirect_to archived_messages_path, alert: result.error
    end
  end

  def create
    if params[:message][:parent_id].present?
      # This is a reply
      result = messages_service.reply(
        parent_id: params[:message][:parent_id],
        body: params[:message][:message]
      )

      if result.success?
        @message = result.message
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to message_path(result.message.thread_root), notice: "Reply sent" }
        end
      else
        @message = Message.new(message_params)
        @message.errors.add(:base, result.error)
        recipients = messages_service.compose_recipients
        @messageable_users = recipients[:users]
        @group_recipients = recipients[:groups]
        render :new, status: :unprocessable_entity
      end
    else
      # This is a new message
      recipient_ids = params[:message][:recipient_ids]&.reject(&:blank?) || []
      result = messages_service.compose(
        subject: params[:message][:subject],
        body: params[:message][:message],
        recipient_ids: recipient_ids,
        reply_mode: params[:message][:reply_mode] || :reply_to_sender
      )

      if result.success?
        count = result.messages&.size || 1
        notice = count > 1 ? "Message sent to #{count} recipients" : "Message sent successfully"
        redirect_to sent_messages_path, notice: notice
      else
        @message = Message.new(message_params)
        @message.errors.add(:base, result.error)
        recipients = messages_service.compose_recipients
        @messageable_users = recipients[:users]
        @group_recipients = recipients[:groups]
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def messages_service
    @messages_service ||= MessagesService.new(current_user)
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def authorize_view
    unless can_view_message?(@message)
      redirect_to messages_path, alert: "You don't have permission to view this message"
    end
  end

  def authorize_recipient_action
    thread_message_ids = @message.thread_root.thread_messages.pluck(:id)
    unless current_user.message_recipients.where(message_id: thread_message_ids).exists?
      redirect_to messages_path, alert: "You don't have permission to perform this action"
    end
  end

  def can_view_message?(message)
    # Author can view
    return true if message.author == current_user

    # Recipients can view
    return true if message.recipients.include?(current_user)

    false
  end

  def message_params
    params.require(:message).permit(:subject, :message, :parent_id, :reply_mode)
  end
end
