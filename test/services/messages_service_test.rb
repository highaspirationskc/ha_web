# frozen_string_literal: true

require "test_helper"

class MessagesServiceTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin_msg_svc@example.com")
    @staff = create_staff_user(email: "staff_msg_svc@example.com")
    @mentor = create_mentor_user(email: "mentor_msg_svc@example.com")
    @mentee_user = create_mentee_user(email: "mentee_msg_svc@example.com", mentor: @mentor.mentor)
    @guardian_user = create_guardian_user(email: "guardian_msg_svc@example.com")

    # Link guardian to mentee
    FamilyMember.create!(mentee: @mentee_user.mentee, guardian: @guardian_user.guardian, relationship_type: "parent")
  end

  # ============================================
  # compose tests
  # ============================================

  test "compose creates a basic message" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Test Subject",
      body: "Test body",
      recipient_ids: [@staff.id.to_s]
    )

    assert result.success?
    assert_not_nil result.message
    assert_equal "Test Subject", result.message.subject
    assert_equal "Test body", result.message.message
    assert_includes result.message.recipients, @staff
  end

  test "compose requires subject" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "",
      body: "Test body",
      recipient_ids: [@staff.id.to_s]
    )

    assert_not result.success?
    assert_match(/subject/i, result.error)
  end

  test "compose requires body" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Test Subject",
      body: "",
      recipient_ids: [@staff.id.to_s]
    )

    assert_not result.success?
    assert_match(/body|message/i, result.error)
  end

  test "compose requires at least one recipient for non-support messages" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Test Subject",
      body: "Test body",
      recipient_ids: []
    )

    assert_not result.success?
    assert_match(/recipient/i, result.error)
  end

  test "compose checks authorization for each recipient" do
    other_mentor = create_mentor_user(email: "other_mentor_msg_svc@example.com")
    service = MessagesService.new(@mentor)

    result = service.compose(
      subject: "Test Subject",
      body: "Test body",
      recipient_ids: [other_mentor.id.to_s]
    )

    assert_not result.success?
    assert_match(/not authorized/i, result.error)
  end

  test "compose with reply_to_all mode" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Group Message",
      body: "Test body",
      recipient_ids: [@staff.id.to_s, @mentor.id.to_s],
      reply_mode: :reply_to_all
    )

    assert result.success?
    assert result.message.reply_to_all?
  end

  test "compose with reply_to_sender and multiple recipients creates separate messages" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Individual Messages",
      body: "Test body",
      recipient_ids: [@staff.id.to_s, @mentor.id.to_s],
      reply_mode: :reply_to_sender
    )

    assert result.success?
    assert_not_nil result.messages
    assert_equal 2, result.messages.size
    assert result.messages.all?(&:reply_to_sender?)
  end

  # Group expansion tests

  test "compose expands group:everyone for staff" do
    other_user = create_volunteer_user(email: "volunteer_msg_svc@example.com")
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Everyone Message",
      body: "Test body",
      recipient_ids: ["group:everyone"],
      reply_mode: :reply_to_all
    )

    assert result.success?
    # Should include all users except sender
    assert_includes result.message.recipients, @staff
    assert_includes result.message.recipients, @mentor
    assert_includes result.message.recipients, @mentee_user
    assert_includes result.message.recipients, @guardian_user
    assert_includes result.message.recipients, other_user
    assert_not_includes result.message.recipients, @admin
  end

  test "compose expands group:staff for staff" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Staff Message",
      body: "Test body",
      recipient_ids: ["group:staff"],
      reply_mode: :reply_to_all
    )

    assert result.success?
    assert_includes result.message.recipients, @staff
  end

  test "compose expands group:mentors for staff" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Mentors Message",
      body: "Test body",
      recipient_ids: ["group:mentors"],
      reply_mode: :reply_to_all
    )

    assert result.success?
    assert_includes result.message.recipients, @mentor
  end

  test "compose expands group:mentees for staff" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Mentees Message",
      body: "Test body",
      recipient_ids: ["group:mentees"],
      reply_mode: :reply_to_all
    )

    assert result.success?
    assert_includes result.message.recipients, @mentee_user
  end

  test "compose expands group:guardians for staff" do
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Guardians Message",
      body: "Test body",
      recipient_ids: ["group:guardians"],
      reply_mode: :reply_to_all
    )

    assert result.success?
    assert_includes result.message.recipients, @guardian_user
  end

  test "compose expands group:team:id for staff" do
    team = Team.create!(name: "Test Team", color: :blue)
    @mentee_user.mentee.update!(team: team)
    service = MessagesService.new(@admin)

    result = service.compose(
      subject: "Team Message",
      body: "Test body",
      recipient_ids: ["group:team:#{team.id}"],
      reply_mode: :reply_to_all
    )

    assert result.success?
    assert_includes result.message.recipients, @mentee_user
  end

  test "compose does not expand groups for non-staff" do
    service = MessagesService.new(@mentor)

    result = service.compose(
      subject: "Invalid Group",
      body: "Test body",
      recipient_ids: ["group:everyone"]
    )

    # Groups should be ignored for non-staff, resulting in no valid recipients
    assert_not result.success?
    assert_match(/recipient/i, result.error)
  end

  # Guardian CC tests

  test "compose CCs guardians when messaging mentee" do
    service = MessagesService.new(@mentor)

    assert_difference "Message.count", 2 do
      result = service.compose(
        subject: "For Mentee",
        body: "Test body",
        recipient_ids: [@mentee_user.id.to_s]
      )

      assert result.success?
    end

    # Original message to mentee
    original = Message.find_by(subject: "For Mentee")
    assert_includes original.recipients, @mentee_user
    assert_not_includes original.recipients, @guardian_user

    # CC message to guardian
    cc_message = Message.find_by(subject: "cc: For Mentee")
    assert_not_nil cc_message, "CC message should be created for guardian"
    assert_includes cc_message.recipients, @guardian_user
    assert_equal original.message, cc_message.message, "CC message should have same body as original"
    assert_equal original.reply_mode, cc_message.reply_mode, "CC message should have same reply_mode as original"
  end

  test "compose does not CC guardian already in recipient list" do
    service = MessagesService.new(@admin)

    # Send to both mentee and guardian
    assert_difference "Message.count", 1 do
      result = service.compose(
        subject: "Family Message",
        body: "Test body",
        recipient_ids: [@mentee_user.id.to_s, @guardian_user.id.to_s],
        reply_mode: :reply_to_all
      )

      assert result.success?
      # Guardian is already a recipient, so no separate CC message
      assert_includes result.message.recipients, @mentee_user
      assert_includes result.message.recipients, @guardian_user
    end

    # No CC message should exist
    cc_message = Message.find_by(subject: "cc: Family Message")
    assert_nil cc_message, "No CC message should be created when guardian is already recipient"
  end

  test "compose does not CC guardian when they are the sender" do
    service = MessagesService.new(@guardian_user)

    # Guardian sends message to their mentee
    assert_difference "Message.count", 1 do
      result = service.compose(
        subject: "From Guardian",
        body: "Message to my child",
        recipient_ids: [@mentee_user.id.to_s]
      )

      assert result.success?
      assert_includes result.message.recipients, @mentee_user
    end

    # No CC message should exist - guardian sent the message
    cc_message = Message.find_by(subject: "cc: From Guardian")
    assert_nil cc_message, "Guardian sender should not be CC'd on their own message"
  end

  # Support message tests

  test "compose support message adds support staff" do
    service = MessagesService.new(@mentee_user)

    result = service.compose(
      subject: "Help Request",
      body: "I need help",
      recipient_ids: ["support"]
    )

    assert result.success?
    assert result.message.support?
    assert result.message.reply_to_all?
    # Admin and staff have support_inbox permission
    assert_includes result.message.recipients, @admin
    assert_includes result.message.recipients, @staff
  end

  test "compose support message skips authorization checks" do
    service = MessagesService.new(@mentee_user)

    # Mentee normally can't message staff, but support bypasses this
    result = service.compose(
      subject: "Support Request",
      body: "Help",
      recipient_ids: ["support"]
    )

    assert result.success?
  end

  # ============================================
  # reply tests
  # ============================================

  test "reply creates reply message" do
    original = Message.create!(
      author: @admin,
      subject: "Original",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @staff
    service = MessagesService.new(@staff)

    result = service.reply(parent_id: original.id, body: "My reply")

    assert result.success?
    assert_equal "Re: Original", result.message.subject
    assert_equal original, result.message.parent
    assert_includes result.message.recipients, @admin
  end

  test "reply adds Re: prefix only once" do
    original = Message.create!(
      author: @admin,
      subject: "Re: Already prefixed",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @staff
    service = MessagesService.new(@staff)

    result = service.reply(parent_id: original.id, body: "My reply")

    assert result.success?
    assert_equal "Re: Already prefixed", result.message.subject
  end

  test "reply requires body" do
    original = Message.create!(
      author: @admin,
      subject: "Original",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @staff
    service = MessagesService.new(@staff)

    result = service.reply(parent_id: original.id, body: "")

    assert_not result.success?
    assert_match(/body|message/i, result.error)
  end

  test "reply fails for non-existent message" do
    service = MessagesService.new(@admin)

    result = service.reply(parent_id: 99999, body: "Reply")

    assert_not result.success?
    assert_match(/not found/i, result.error)
  end

  test "reply fails when not thread participant" do
    original = Message.create!(
      author: @admin,
      subject: "Original",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @staff
    service = MessagesService.new(@mentor)

    result = service.reply(parent_id: original.id, body: "Unauthorized reply")

    assert_not result.success?
    assert_match(/not authorized/i, result.error)
  end

  test "reply allowed for staff/admin even when not participant" do
    original = Message.create!(
      author: @mentor,
      subject: "Original",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @mentee_user
    service = MessagesService.new(@admin)

    result = service.reply(parent_id: original.id, body: "Admin reply")

    assert result.success?
  end

  test "reply fails for no_replies mode" do
    original = Message.create!(
      author: @admin,
      subject: "No Reply",
      message: "Cannot reply",
      reply_mode: :no_replies
    )
    original.recipients << @staff
    service = MessagesService.new(@staff)

    result = service.reply(parent_id: original.id, body: "Attempted reply")

    assert_not result.success?
    assert_match(/replies are not allowed/i, result.error)
  end

  test "reply_to_all sends to all thread participants" do
    original = Message.create!(
      author: @admin,
      subject: "Group Thread",
      message: "Hello everyone",
      reply_mode: :reply_to_all
    )
    original.recipients << @staff
    original.recipients << @mentor
    service = MessagesService.new(@staff)

    result = service.reply(parent_id: original.id, body: "Reply to all")

    assert result.success?
    # Should go to all participants except replier
    assert_includes result.message.recipients, @admin
    assert_includes result.message.recipients, @mentor
    assert_not_includes result.message.recipients, @staff
  end

  test "reply_to_sender only sends to original author" do
    original = Message.create!(
      author: @admin,
      subject: "Thread",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @staff
    original.recipients << @mentor
    service = MessagesService.new(@staff)

    result = service.reply(parent_id: original.id, body: "Private reply")

    assert result.success?
    assert_includes result.message.recipients, @admin
    assert_not_includes result.message.recipients, @mentor
  end

  test "reply CCs guardians when replying to mentee" do
    # Admin sends message to mentee
    original = Message.create!(
      author: @admin,
      subject: "To Mentee",
      message: "Hello mentee",
      reply_mode: :reply_to_all
    )
    original.recipients << @mentee_user

    # Admin replies to the mentee (mentee is in recipients of reply)
    service = MessagesService.new(@admin)

    # Should create reply + CC for guardian
    assert_difference "Message.count", 2 do
      result = service.reply(parent_id: original.id, body: "Follow up message")

      assert result.success?
      assert_includes result.message.recipients, @mentee_user
    end

    # CC message should exist for guardian
    cc_message = Message.find_by(subject: "cc: Re: To Mentee")
    assert_not_nil cc_message, "Guardian should receive CC of reply to mentee"
    assert_includes cc_message.recipients, @guardian_user
  end

  test "reply does not CC guardian who is already thread participant" do
    # Message to both mentee and guardian
    original = Message.create!(
      author: @admin,
      subject: "Family Thread",
      message: "Hello family",
      reply_mode: :reply_to_all
    )
    original.recipients << @mentee_user
    original.recipients << @guardian_user

    service = MessagesService.new(@admin)

    # Reply should only create 1 message (no CC needed)
    assert_difference "Message.count", 1 do
      result = service.reply(parent_id: original.id, body: "Follow up")

      assert result.success?
      assert_includes result.message.recipients, @mentee_user
      assert_includes result.message.recipients, @guardian_user
    end

    # No CC message should exist
    cc_message = Message.find_by(subject: "cc: Re: Family Thread")
    assert_nil cc_message, "No CC when guardian is already in thread"
  end

  test "reply does not CC guardian when they are replying" do
    # Mentee initiates message to guardian
    original = Message.create!(
      author: @mentee_user,
      subject: "From Mentee",
      message: "Hello guardian",
      reply_mode: :reply_to_all
    )
    original.recipients << @guardian_user

    # Guardian replies - should not CC themselves
    service = MessagesService.new(@guardian_user)

    assert_difference "Message.count", 1 do
      result = service.reply(parent_id: original.id, body: "Reply from guardian")

      assert result.success?
      assert_includes result.message.recipients, @mentee_user
    end

    # No CC message should exist
    cc_message = Message.find_by(subject: "cc: Re: From Mentee")
    assert_nil cc_message, "Guardian replier should not be CC'd"
  end

  # ============================================
  # archive / unarchive tests
  # ============================================

  test "archive archives entire thread" do
    original = Message.create!(
      author: @admin,
      subject: "Thread to Archive",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @staff

    reply = Message.create!(
      author: @staff,
      parent: original,
      subject: "Re: Thread to Archive",
      message: "Reply",
      reply_mode: :reply_to_sender
    )
    reply.recipients << @admin

    service = MessagesService.new(@staff)
    result = service.archive(message_id: original.id)

    assert result.success?
    # Both messages in thread should be archived for staff
    assert @staff.message_recipients.find_by(message: original).archived
  end

  test "archive fails for non-recipient" do
    original = Message.create!(
      author: @admin,
      subject: "Not Your Thread",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    original.recipients << @staff
    service = MessagesService.new(@mentor)

    result = service.archive(message_id: original.id)

    assert_not result.success?
    assert_match(/not a recipient/i, result.error)
  end

  test "archive fails for non-existent message" do
    service = MessagesService.new(@admin)

    result = service.archive(message_id: 99999)

    assert_not result.success?
    assert_match(/not found/i, result.error)
  end

  test "unarchive unarchives entire thread" do
    original = Message.create!(
      author: @admin,
      subject: "Thread to Unarchive",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    mr = MessageRecipient.create!(message: original, recipient: @staff, archived: true)

    service = MessagesService.new(@staff)
    result = service.unarchive(message_id: original.id)

    assert result.success?
    assert_not mr.reload.archived
  end

  # ============================================
  # mark_thread_read tests
  # ============================================

  test "mark_thread_read marks all thread messages as read" do
    original = Message.create!(
      author: @admin,
      subject: "Unread Thread",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    mr = MessageRecipient.create!(message: original, recipient: @staff, is_read: false)

    service = MessagesService.new(@staff)
    result = service.mark_thread_read(message_id: original.id)

    assert result.success?
    assert mr.reload.is_read
  end

  test "mark_thread_read fails for non-existent message" do
    service = MessagesService.new(@admin)

    result = service.mark_thread_read(message_id: 99999)

    assert_not result.success?
    assert_match(/not found/i, result.error)
  end

  test "mark_thread_read marks thread with one reply as read" do
    original = Message.create!(
      author: @admin,
      subject: "Thread with reply",
      message: "Original message",
      reply_mode: :reply_to_all
    )
    mr_original = MessageRecipient.create!(message: original, recipient: @staff, is_read: false)

    reply = Message.create!(
      author: @admin,
      parent: original,
      subject: "Re: Thread with reply",
      message: "Reply message",
      reply_mode: :reply_to_all
    )
    mr_reply = MessageRecipient.create!(message: reply, recipient: @staff, is_read: false)

    service = MessagesService.new(@staff)
    result = service.mark_thread_read(message_id: original.id)

    assert result.success?
    assert mr_original.reload.is_read, "Original message should be marked as read"
    assert mr_reply.reload.is_read, "Reply should be marked as read"
  end

  test "mark_thread_read marks thread with multiple replies as read" do
    original = Message.create!(
      author: @admin,
      subject: "Thread with multiple replies",
      message: "Original message",
      reply_mode: :reply_to_all
    )
    mr_original = MessageRecipient.create!(message: original, recipient: @staff, is_read: false)

    reply1 = Message.create!(
      author: @admin,
      parent: original,
      subject: "Re: Thread with multiple replies",
      message: "First reply",
      reply_mode: :reply_to_all
    )
    mr_reply1 = MessageRecipient.create!(message: reply1, recipient: @staff, is_read: false)

    reply2 = Message.create!(
      author: @admin,
      parent: original,
      subject: "Re: Thread with multiple replies",
      message: "Second reply",
      reply_mode: :reply_to_all
    )
    mr_reply2 = MessageRecipient.create!(message: reply2, recipient: @staff, is_read: false)

    reply3 = Message.create!(
      author: @admin,
      parent: original,
      subject: "Re: Thread with multiple replies",
      message: "Third reply",
      reply_mode: :reply_to_all
    )
    mr_reply3 = MessageRecipient.create!(message: reply3, recipient: @staff, is_read: false)

    service = MessagesService.new(@staff)
    result = service.mark_thread_read(message_id: original.id)

    assert result.success?
    assert mr_original.reload.is_read, "Original message should be marked as read"
    assert mr_reply1.reload.is_read, "First reply should be marked as read"
    assert mr_reply2.reload.is_read, "Second reply should be marked as read"
    assert mr_reply3.reload.is_read, "Third reply should be marked as read"
  end

  # ============================================
  # list method tests
  # ============================================

  test "inbox returns thread roots for received messages" do
    message = Message.create!(
      author: @admin,
      subject: "Inbox Test",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    message.recipients << @staff
    service = MessagesService.new(@staff)

    inbox = service.inbox

    assert_includes inbox, message
  end

  test "inbox excludes archived messages" do
    message = Message.create!(
      author: @admin,
      subject: "Archived",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: message, recipient: @staff, archived: true)
    service = MessagesService.new(@staff)

    inbox = service.inbox

    assert_not_includes inbox, message
  end

  test "inbox orders support messages first" do
    regular = Message.create!(
      author: @admin,
      subject: "Regular",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    regular.recipients << @staff

    support = Message.create!(
      author: @mentee_user,
      subject: "Support",
      message: "Help",
      reply_mode: :reply_to_all,
      support: true
    )
    support.recipients << @staff
    service = MessagesService.new(@staff)

    inbox = service.inbox.to_a

    assert_equal support, inbox.first
  end

  test "sent returns authored root messages" do
    message = Message.create!(
      author: @admin,
      subject: "Sent Test",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    message.recipients << @staff
    service = MessagesService.new(@admin)

    sent = service.sent

    assert_includes sent, message
  end

  test "archived returns archived thread roots" do
    message = Message.create!(
      author: @admin,
      subject: "Archived Test",
      message: "Hello",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: message, recipient: @staff, archived: true)
    service = MessagesService.new(@staff)

    archived = service.archived

    assert_includes archived, message
  end

  # ============================================
  # compose_recipients tests
  # ============================================

  test "compose_recipients returns users for non-staff" do
    service = MessagesService.new(@mentor)

    result = service.compose_recipients

    assert_includes result[:users], @mentee_user
    # Non-staff only gets support group
    assert_equal 1, result[:groups].size
    assert_equal "support", result[:groups].first[:id]
  end

  test "compose_recipients returns users and groups for staff" do
    service = MessagesService.new(@admin)

    result = service.compose_recipients

    assert result[:users].any?
    # Staff gets all group options
    group_ids = result[:groups].map { |g| g[:id] }
    assert_includes group_ids, "support"
    assert_includes group_ids, "group:everyone"
    assert_includes group_ids, "group:staff"
    assert_includes group_ids, "group:mentors"
    assert_includes group_ids, "group:mentees"
    assert_includes group_ids, "group:guardians"
  end

  test "compose_recipients includes team groups for staff" do
    team = Team.create!(name: "Alpha Team", color: :green)
    service = MessagesService.new(@admin)

    result = service.compose_recipients

    group_ids = result[:groups].map { |g| g[:id] }
    assert_includes group_ids, "group:team:#{team.id}"
  end
end
