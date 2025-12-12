class MessagesController < AuthenticatedController
  before_action { require_navigation_access(:inbox) }
  before_action :set_message, only: [:show, :archive, :unarchive]
  before_action :authorize_view, only: [:show]
  before_action :authorize_recipient_action, only: [:archive, :unarchive]

  def index
    # Get root messages where user is a recipient (not archived) of the root OR any reply
    non_archived_recipients = current_user.message_recipients.not_archived
    root_ids_from_direct = non_archived_recipients.joins(:message).where(messages: { parent_id: nil }).pluck(:message_id)
    root_ids_from_replies = non_archived_recipients.joins(:message).where.not(messages: { parent_id: nil }).pluck("messages.parent_id")

    all_root_ids = (root_ids_from_direct + root_ids_from_replies).uniq

    @messages = Message.where(id: all_root_ids)
                       .includes(:author, :message_recipients)
                       .order(support: :desc, created_at: :desc)
  end

  def sent
    @messages = current_user.sent_messages
                            .includes(:recipients)
                            .roots
                            .recent
  end

  def archived
    # Get root messages where user has archived messages
    archived_recipients = current_user.message_recipients.archived
    root_ids_from_direct = archived_recipients.joins(:message).where(messages: { parent_id: nil }).pluck(:message_id)
    root_ids_from_replies = archived_recipients.joins(:message).where.not(messages: { parent_id: nil }).pluck("messages.parent_id")

    all_root_ids = (root_ids_from_direct + root_ids_from_replies).uniq

    @messages = Message.where(id: all_root_ids)
                       .includes(:author, :message_recipients)
                       .recent
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

    # Mark visible messages as read for current user
    MessageRecipient.where(message_id: @thread_messages.map(&:id), recipient: current_user, is_read: false)
                    .update_all(is_read: true)

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

    @messageable_users = Authorization.messageable_users(current_user).order(:first_name, :last_name)
    @group_recipients = build_group_recipients if current_user.staff?
  end

  def archive
    thread_message_ids = @message.thread_root.thread_messages.pluck(:id)
    current_user.message_recipients.where(message_id: thread_message_ids).update_all(archived: true)
    redirect_to messages_path, notice: "Message archived"
  end

  def unarchive
    thread_message_ids = @message.thread_root.thread_messages.pluck(:id)
    current_user.message_recipients.where(message_id: thread_message_ids).update_all(archived: false)
    redirect_to archived_messages_path, notice: "Message moved to inbox"
  end

  def create
    @message = Message.new(message_params)
    @message.author = current_user

    # Validate and expand recipients (groups get expanded to individual users)
    recipient_ids = params[:message][:recipient_ids]&.reject(&:blank?) || []

    # Check if this is a support message
    is_support_message = recipient_ids.include?("support")
    recipient_ids = recipient_ids.reject { |id| id == "support" }

    if is_support_message
      @message.support = true
      @message.reply_mode = :reply_to_all  # Support messages are group conversations
    end

    expanded_ids = expand_group_recipients(recipient_ids)
    recipients = User.where(id: expanded_ids)

    # Get parent message for reply permission checking
    parent_message = @message.parent_id.present? ? Message.find_by(id: @message.parent_id) : nil

    # Check permissions for each recipient (skip for support messages - anyone can message support)
    unless is_support_message
      unauthorized_recipients = recipients.reject do |recipient|
        Authorization.can_message?(current_user, recipient, in_thread_with: parent_message)
      end

      if unauthorized_recipients.any?
        @message.errors.add(:base, "You don't have permission to message some of the selected recipients")
        @messageable_users = Authorization.messageable_users(current_user).order(:first_name, :last_name)
        render :new, status: :unprocessable_entity
        return
      end
    end

    # For reply_to_sender with multiple recipients, create separate messages
    if @message.reply_to_sender? && recipients.size > 1 && @message.parent_id.blank?
      create_separate_messages_for_recipients(recipients)
    else
      if @message.save
        # Add recipients
        recipients.each do |recipient|
          @message.recipients << recipient
        end

        # For support messages, add all users with support_inbox permission as recipients
        if is_support_message
          support_users = Authorization.users_with_permission(:support_inbox, :messages)
                                       .where.not(id: current_user.id)
          support_users.each do |user|
            @message.recipients << user unless @message.recipients.include?(user)
          end
        end

        # Auto-add guardians when messaging mentees
        add_guardians_for_mentees(recipients)

        # Broadcast to recipients for real-time updates
        @message.broadcast_to_recipients

        if @message.reply?
          respond_to do |format|
            format.turbo_stream
            format.html { redirect_to message_path(@message.thread_root), notice: "Reply sent" }
          end
        else
          redirect_to sent_messages_path, notice: "Message sent successfully"
        end
      else
        @messageable_users = Authorization.messageable_users(current_user).order(:first_name, :last_name)
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

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

  def create_separate_messages_for_recipients(recipients)
    # Create a separate message for each recipient (for reply_to_sender mode)
    messages_created = []

    recipients.each do |recipient|
      msg = Message.new(
        author: current_user,
        subject: @message.subject,
        message: @message.message,
        reply_mode: :reply_to_sender
      )

      if msg.save
        msg.recipients << recipient
        add_guardians_for_mentee(msg, recipient)
        msg.broadcast_to_recipients
        messages_created << msg
      end
    end

    if messages_created.any?
      redirect_to sent_messages_path, notice: "Message sent to #{messages_created.size} recipient#{'s' if messages_created.size > 1}"
    else
      @message.errors.add(:base, "Failed to send messages")
      @messageable_users = Authorization.messageable_users(current_user).order(:first_name, :last_name)
      render :new, status: :unprocessable_entity
    end
  end

  def add_guardians_for_mentees(recipients)
    recipients.each do |recipient|
      add_guardians_for_mentee(@message, recipient)
    end
  end

  def build_group_recipients
    groups = []

    # Everyone
    groups << { id: "group:everyone", name: "Everyone", description: "All users" }

    # Role-based groups
    groups << { id: "group:staff", name: "Staff", description: "All staff members" }
    groups << { id: "group:mentors", name: "Mentors", description: "All mentors" }
    groups << { id: "group:mentees", name: "Mentees", description: "All mentees" }
    groups << { id: "group:guardians", name: "Guardians", description: "All guardians" }

    # Team-based groups
    Team.order(:name).each do |team|
      groups << { id: "group:team:#{team.id}", name: team.name, description: "All members of #{team.name}" }
    end

    groups
  end

  def expand_group_recipients(recipient_ids)
    expanded_ids = []

    recipient_ids.each do |id|
      if id.start_with?("group:")
        expanded_ids.concat(expand_group(id))
      else
        expanded_ids << id
      end
    end

    expanded_ids.uniq
  end

  def expand_group(group_id)
    case group_id
    when "group:everyone"
      User.where.not(id: current_user.id).pluck(:id)
    when "group:staff"
      User.joins(:staff).pluck(:id)
    when "group:mentors"
      User.joins(:mentor).pluck(:id)
    when "group:mentees"
      User.joins(:mentee).pluck(:id)
    when "group:guardians"
      User.joins(:guardian).pluck(:id)
    when /^group:team:(\d+)$/
      team_id = $1.to_i
      User.joins(mentee: :team).where(teams: { id: team_id }).pluck(:id)
    else
      []
    end
  end

  def add_guardians_for_mentee(message, recipient)
    return unless recipient.mentee?

    # Get guardians of this mentee
    guardian_user_ids = recipient.mentee.family_members
                                 .joins(guardian: :user)
                                 .pluck("users.id")

    guardian_user_ids.each do |guardian_id|
      # Don't add if already a recipient
      unless message.recipients.exists?(id: guardian_id)
        guardian = User.find(guardian_id)
        message.recipients << guardian
      end
    end
  end
end
