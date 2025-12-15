# frozen_string_literal: true

class MessagesService
  Result = Struct.new(:success?, :message, :messages, :error, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def compose(subject:, body:, recipient_ids:, reply_mode: :reply_to_sender, support: false)
    return Result.new(success?: false, error: "Subject is required") if subject.blank?
    return Result.new(success?: false, error: "Message body is required") if body.blank?

    # Detect support message
    is_support = support || recipient_ids.include?("support")
    recipient_ids = recipient_ids.reject { |id| id == "support" }

    if is_support
      reply_mode = :reply_to_all
    end

    # Expand group recipients (staff only)
    expanded_ids = expand_group_recipients(recipient_ids)

    # Get valid recipients
    recipients = User.where(id: expanded_ids).to_a

    # For support messages, add support staff
    if is_support
      support_staff = Authorization.users_with_permission(:support_inbox, :messages)
                                   .where.not(id: @user.id)
                                   .to_a
      recipients = (recipients + support_staff).uniq
    end

    if recipients.empty? && !is_support
      return Result.new(success?: false, error: "At least one recipient is required")
    end

    # Check authorization (skip for support messages)
    unless is_support
      unauthorized = recipients.reject { |r| Authorization.can_message?(@user, r) }
      if unauthorized.any?
        names = unauthorized.map { |u| "#{u.first_name} #{u.last_name}" }.join(", ")
        return Result.new(success?: false, error: "You are not authorized to message: #{names}")
      end
    end

    # Identify guardians to CC (those not already in recipient list)
    guardians_to_cc = find_guardians_to_cc(recipients)

    reply_mode_sym = reply_mode.to_s.to_sym

    # Handle reply_to_sender with multiple recipients - create separate messages
    if reply_mode_sym == :reply_to_sender && recipients.size > 1
      result = create_separate_messages(subject, body, recipients, is_support)
      # CC guardians for each mentee
      create_guardian_cc_messages(subject, guardians_to_cc) if guardians_to_cc.any?
      result
    else
      result = create_single_message(subject, body, recipients, reply_mode_sym, is_support)
      # CC guardians who aren't already recipients
      create_guardian_cc_messages(subject, guardians_to_cc) if result.success? && guardians_to_cc.any?
      result
    end
  end

  def reply(parent_id:, body:)
    return Result.new(success?: false, error: "Message body is required") if body.blank?

    parent = Message.find_by(id: parent_id)
    return Result.new(success?: false, error: "Message not found") unless parent

    thread_root = parent.thread_root

    unless can_reply_to?(thread_root)
      return Result.new(success?: false, error: "You are not authorized to reply to this message")
    end

    if thread_root.no_replies?
      return Result.new(success?: false, error: "Replies are not allowed for this message")
    end

    recipients = determine_reply_recipients(thread_root)
    subject = thread_root.subject.start_with?("Re: ") ? thread_root.subject : "Re: #{thread_root.subject}"

    message = Message.new(
      author: @user,
      parent: thread_root,
      subject: subject,
      message: body,
      reply_mode: thread_root.reply_mode,
      support: thread_root.support
    )

    if message.save
      recipients.each { |r| message.recipients << r }
      message.broadcast_to_recipients
      Result.new(success?: true, message: message)
    else
      Result.new(success?: false, error: message.errors.full_messages.join(", "))
    end
  end

  def archive(message_id:)
    message = Message.find_by(id: message_id)
    return Result.new(success?: false, error: "Message not found") unless message

    thread_message_ids = message.thread_root.thread_messages.pluck(:id)
    user_recipients = @user.message_recipients.where(message_id: thread_message_ids)

    if user_recipients.empty?
      return Result.new(success?: false, error: "You are not a recipient of this thread")
    end

    user_recipients.update_all(archived: true)
    Result.new(success?: true, message: message.thread_root)
  end

  def unarchive(message_id:)
    message = Message.find_by(id: message_id)
    return Result.new(success?: false, error: "Message not found") unless message

    thread_message_ids = message.thread_root.thread_messages.pluck(:id)
    user_recipients = @user.message_recipients.where(message_id: thread_message_ids)

    if user_recipients.empty?
      return Result.new(success?: false, error: "You are not a recipient of this thread")
    end

    user_recipients.update_all(archived: false)
    Result.new(success?: true, message: message.thread_root)
  end

  def mark_thread_read(message_id:)
    message = Message.find_by(id: message_id)
    return Result.new(success?: false, error: "Message not found") unless message

    thread_message_ids = message.thread_root.thread_messages.pluck(:id)

    MessageRecipient.where(
      message_id: thread_message_ids,
      recipient: @user
    ).update_all(is_read: true)

    Result.new(success?: true, message: message.thread_root)
  end

  def inbox
    non_archived_recipients = @user.message_recipients.not_archived
    root_ids_from_direct = non_archived_recipients.joins(:message)
                                                  .where(messages: { parent_id: nil })
                                                  .pluck(:message_id)
    root_ids_from_replies = non_archived_recipients.joins(:message)
                                                   .where.not(messages: { parent_id: nil })
                                                   .pluck("messages.parent_id")

    all_root_ids = (root_ids_from_direct + root_ids_from_replies).uniq

    Message.where(id: all_root_ids)
           .includes(:author, :message_recipients)
           .order(support: :desc, created_at: :desc)
  end

  def sent
    @user.sent_messages.roots.includes(:recipients).order(created_at: :desc)
  end

  def archived
    archived_recipients = @user.message_recipients.archived
    root_ids_from_direct = archived_recipients.joins(:message)
                                              .where(messages: { parent_id: nil })
                                              .pluck(:message_id)
    root_ids_from_replies = archived_recipients.joins(:message)
                                               .where.not(messages: { parent_id: nil })
                                               .pluck("messages.parent_id")

    all_root_ids = (root_ids_from_direct + root_ids_from_replies).uniq

    Message.where(id: all_root_ids)
           .includes(:author, :message_recipients)
           .order(created_at: :desc)
  end

  def compose_recipients
    users = Authorization.messageable_users(@user).order(:first_name, :last_name)
    groups = build_group_options

    { users: users, groups: groups }
  end

  private

  def expand_group_recipients(recipient_ids)
    return recipient_ids.map(&:to_i) unless @user.staff?

    expanded_ids = []

    recipient_ids.each do |id|
      if id.to_s.start_with?("group:")
        expanded_ids.concat(expand_group(id))
      else
        expanded_ids << id.to_i
      end
    end

    expanded_ids.uniq
  end

  def expand_group(group_id)
    ids = case group_id
    when "group:everyone"
      User.pluck(:id)
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

    # Always exclude the sender from group recipients
    ids - [@user.id]
  end

  def find_guardians_to_cc(recipients)
    guardians_to_cc = []
    recipient_ids = recipients.map(&:id)

    recipients.each do |recipient|
      next unless recipient.mentee?

      guardian_user_ids = recipient.mentee.family_members
                                   .joins(guardian: :user)
                                   .pluck("users.id")

      guardian_user_ids.each do |guardian_id|
        # Only CC if guardian is NOT already a recipient
        unless recipient_ids.include?(guardian_id)
          guardian = User.find_by(id: guardian_id)
          guardians_to_cc << guardian if guardian
        end
      end
    end

    guardians_to_cc.uniq
  end

  def create_guardian_cc_messages(original_subject, guardians)
    guardians.each do |guardian|
      cc_message = Message.new(
        author: @user,
        subject: "cc: #{original_subject}",
        message: "This is a copy of a message sent to your mentee.",
        reply_mode: :no_replies
      )

      if cc_message.save
        cc_message.recipients << guardian
        cc_message.broadcast_to_recipients
      end
    end
  end

  def create_separate_messages(subject, body, recipients, support)
    messages_created = []

    recipients.each do |recipient|
      msg = Message.new(
        author: @user,
        subject: subject,
        message: body,
        reply_mode: :reply_to_sender,
        support: support
      )

      if msg.save
        msg.recipients << recipient
        msg.broadcast_to_recipients
        messages_created << msg
      end
    end

    if messages_created.any?
      Result.new(success?: true, messages: messages_created, message: messages_created.first)
    else
      Result.new(success?: false, error: "Failed to send messages")
    end
  end

  def create_single_message(subject, body, recipients, reply_mode, support)
    message = Message.new(
      author: @user,
      subject: subject,
      message: body,
      reply_mode: reply_mode,
      support: support
    )

    if message.save
      recipients.each { |r| message.recipients << r }
      message.broadcast_to_recipients
      Result.new(success?: true, message: message)
    else
      Result.new(success?: false, error: message.errors.full_messages.join(", "))
    end
  end

  def can_reply_to?(thread_root)
    return true if @user.can?(:reply_any, :messages)
    thread_root.thread_participants.include?(@user)
  end

  def determine_reply_recipients(thread_root)
    if thread_root.reply_to_all?
      thread_root.thread_participants.reject { |u| u == @user }
    elsif thread_root.author == @user
      # Replying to own message - send to original recipients
      thread_root.recipients.to_a
    else
      # Reply to sender only
      [thread_root.author]
    end
  end

  def build_group_options
    groups = [
      { id: "support", name: "Support", description: "Contact support" }
    ]

    return groups unless @user.staff?

    groups.concat([
      { id: "group:everyone", name: "Everyone", description: "All users" },
      { id: "group:staff", name: "Staff", description: "All staff members" },
      { id: "group:mentors", name: "Mentors", description: "All mentors" },
      { id: "group:mentees", name: "Mentees", description: "All mentees" },
      { id: "group:guardians", name: "Guardians", description: "All guardians" }
    ])

    Team.order(:name).each do |team|
      groups << { id: "group:team:#{team.id}", name: team.name, description: "All members of #{team.name}" }
    end

    groups
  end
end
