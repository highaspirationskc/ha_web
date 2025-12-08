class Message < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :author, class_name: "User"
  belongs_to :parent, class_name: "Message", optional: true

  has_many :replies, class_name: "Message", foreign_key: :parent_id, dependent: :destroy
  has_many :message_recipients, dependent: :destroy
  has_many :recipients, through: :message_recipients, source: :recipient

  # Reply mode determines who recipients can reply to
  # no_replies: recipients cannot reply
  # reply_to_sender: recipients can only reply to the sender (creates separate threads per recipient)
  # reply_to_all: recipients can reply to all recipients (single thread)
  enum :reply_mode, { no_replies: 0, reply_to_sender: 1, reply_to_all: 2 }

  validates :subject, presence: true
  validates :message, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :roots, -> { where(parent_id: nil) }
  scope :support_requests, -> { where(support: true) }

  def thread_root
    parent_id? ? parent.thread_root : self
  end

  def thread_messages
    root = thread_root
    # Get the root message and all its direct replies
    Message.where(id: root.id).or(Message.where(parent_id: root.id)).order(:created_at)
  end

  def reply?
    parent_id.present?
  end

  # Returns recipients visible to a specific user based on reply mode
  # For reply_to_all: all recipients
  # For no_replies/reply_to_sender: only the user and their family members
  def visible_recipients_for(user)
    all_recipients = recipients.to_a

    if reply_to_all?
      all_recipients
    else
      # Only show recipients relevant to this user
      # Includes the user themselves and any family members (guardian sees their mentee)
      family_member_ids = user.guardian&.family_members&.joins(mentee: :user)&.pluck("users.id") || []
      all_recipients.select { |r| r == user || family_member_ids.include?(r.id) }
    end
  end

  # Returns display string for recipients
  # Support messages show "Support", others show recipient names
  def recipients_display_for(user)
    return "Support" if support?

    visible_recipients_for(user).map do |r|
      r == user ? "Me" : "#{r.first_name} #{r.last_name}"
    end.join(", ")
  end

  # Broadcast to all recipients for real-time updates
  def broadcast_to_recipients
    # Broadcast to thread viewers (for replies)
    if reply?
      broadcast_append_to(
        "message_thread_#{thread_root.id}",
        target: "thread-messages",
        partial: "messages/message",
        locals: { message: self }
      )

      # Update thread message count
      thread_count = thread_root.thread_messages.count
      broadcast_replace_to(
        "message_thread_#{thread_root.id}",
        target: "thread-message-count",
        html: "<p id=\"thread-message-count\" class=\"mt-1 text-sm text-gray-500\">#{thread_count} message#{'s' if thread_count != 1} in this thread</p>"
      )
    end

    # Broadcast unread count update to all thread participants (not just this message's recipients)
    thread_participants.each do |participant|
      next if participant == author # Don't update sender's own unread count
      broadcast_unread_count_to(participant)
    end
  end

  # All users involved in this thread (authors + recipients)
  def thread_participants
    root = thread_root
    messages = root.thread_messages.includes(:author, :recipients)

    participants = Set.new
    messages.each do |msg|
      participants << msg.author
      msg.recipients.each { |r| participants << r }
    end
    participants.to_a
  end

  def broadcast_unread_count_to(user)
    count = user.unread_message_count
    hidden_class = count > 0 ? "" : "hidden"

    # Update both mobile and desktop badges
    %w[mobile desktop].each do |variant|
      broadcast_replace_to(
        "inbox_#{user.id}",
        target: "unread-badge-#{variant}",
        html: "<span id=\"unread-badge-#{variant}\" class=\"#{hidden_class} ml-auto w-5 min-w-max whitespace-nowrap rounded-full bg-indigo-600 px-2 py-0.5 text-center text-xs font-medium text-white ring-1 ring-inset ring-indigo-500\">#{count}</span>"
      )
    end

    # Update or prepend inbox row
    root = thread_root
    if reply?
      # Update existing row (move to top and refresh)
      broadcast_remove_to("inbox_#{user.id}", target: "inbox-row-#{root.id}")
    end
    broadcast_prepend_to(
      "inbox_#{user.id}",
      target: "inbox-messages",
      partial: "messages/inbox_row",
      locals: { message: root, user: user }
    )
  end
end
