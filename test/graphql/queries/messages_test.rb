require "test_helper"

class MessagesQueriesTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin@example.com")
    @staff = create_staff_user(email: "staff@example.com")
    @mentor = create_mentor_user(email: "mentor@example.com")
  end

  # inbox tests

  test "can query inbox messages" do
    message = Message.create!(
      author: @admin,
      subject: "Inbox Message",
      message: "Message body",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: message, recipient: @staff)

    query = <<~GQL
      query {
        inbox {
          id
          subject
          message
          author {
            id
            email
          }
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @staff })
    inbox = result.dig("data", "inbox")

    assert_equal 1, inbox.length
    assert_equal "Inbox Message", inbox.first["subject"]
    assert_equal @admin.email, inbox.first.dig("author", "email")
  end

  test "inbox excludes archived messages" do
    message1 = Message.create!(
      author: @admin,
      subject: "Not Archived",
      message: "Body",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: message1, recipient: @staff, archived: false)

    message2 = Message.create!(
      author: @admin,
      subject: "Archived",
      message: "Body",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: message2, recipient: @staff, archived: true)

    query = <<~GQL
      query {
        inbox {
          id
          subject
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @staff })
    inbox = result.dig("data", "inbox")

    assert_equal 1, inbox.length
    assert_equal "Not Archived", inbox.first["subject"]
  end

  test "inbox groups messages by thread" do
    root = Message.create!(
      author: @admin,
      subject: "Thread Root",
      message: "Original",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: root, recipient: @staff)

    reply = Message.create!(
      author: @staff,
      parent: root,
      subject: "Re: Thread Root",
      message: "Reply",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: reply, recipient: @admin)

    query = <<~GQL
      query {
        inbox {
          id
          subject
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @staff })
    inbox = result.dig("data", "inbox")

    assert_equal 1, inbox.length
    assert_equal root.id.to_s, inbox.first["id"]
  end

  test "inbox requires authentication" do
    query = <<~GQL
      query {
        inbox {
          id
        }
      }
    GQL

    result = execute_graphql(query, context: {})
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  # sentMessages tests

  test "can query sent messages" do
    message = Message.create!(
      author: @admin,
      subject: "Sent Message",
      message: "Body",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: message, recipient: @staff)

    query = <<~GQL
      query {
        sentMessages {
          id
          subject
          recipients {
            id
            email
          }
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @admin })
    sent = result.dig("data", "sentMessages")

    assert_equal 1, sent.length
    assert_equal "Sent Message", sent.first["subject"]
    assert_equal @staff.email, sent.first.dig("recipients").first["email"]
  end

  test "sent messages only includes root messages" do
    root = Message.create!(
      author: @admin,
      subject: "Root",
      message: "Original",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: root, recipient: @staff)

    reply = Message.create!(
      author: @admin,
      parent: root,
      subject: "Re: Root",
      message: "My reply",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: reply, recipient: @staff)

    query = <<~GQL
      query {
        sentMessages {
          id
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @admin })
    sent = result.dig("data", "sentMessages")

    assert_equal 1, sent.length
    assert_equal root.id.to_s, sent.first["id"]
  end

  # archivedMessages tests

  test "can query archived messages" do
    message = Message.create!(
      author: @admin,
      subject: "Archived Message",
      message: "Body",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: message, recipient: @staff, archived: true)

    query = <<~GQL
      query {
        archivedMessages {
          id
          subject
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @staff })
    archived = result.dig("data", "archivedMessages")

    assert_equal 1, archived.length
    assert_equal "Archived Message", archived.first["subject"]
  end

  # messageThread tests

  test "can query message thread" do
    root = Message.create!(
      author: @admin,
      subject: "Thread",
      message: "Original",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: root, recipient: @staff, is_read: false)

    reply = Message.create!(
      author: @staff,
      parent: root,
      subject: "Re: Thread",
      message: "Reply",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: reply, recipient: @admin)

    query = <<~GQL
      query($messageId: ID!) {
        messageThread(messageId: $messageId) {
          id
          subject
          replies {
            id
            subject
          }
        }
      }
    GQL

    result = execute_graphql(query, variables: { messageId: root.id.to_s }, context: { current_user: @staff })
    thread = result.dig("data", "messageThread")

    assert_equal root.id.to_s, thread["id"]
    assert_equal 1, thread["replies"].length
    assert_equal reply.id.to_s, thread["replies"].first["id"]
  end

  test "message thread marks messages as read" do
    message = Message.create!(
      author: @admin,
      subject: "Mark Read",
      message: "Body",
      reply_mode: :reply_to_sender
    )
    recipient = MessageRecipient.create!(message: message, recipient: @staff, is_read: false)

    query = <<~GQL
      query($messageId: ID!) {
        messageThread(messageId: $messageId) {
          id
        }
      }
    GQL

    execute_graphql(query, variables: { messageId: message.id.to_s }, context: { current_user: @staff })

    assert recipient.reload.is_read
  end

  test "message thread marks all replies as read" do
    root = Message.create!(
      author: @admin,
      subject: "Thread with replies",
      message: "Original message",
      reply_mode: :reply_to_all
    )
    root_recipient = MessageRecipient.create!(message: root, recipient: @staff, is_read: false)

    reply1 = Message.create!(
      author: @mentor,
      parent: root,
      subject: "Re: Thread with replies",
      message: "First reply",
      reply_mode: :reply_to_all
    )
    reply1_recipient = MessageRecipient.create!(message: reply1, recipient: @staff, is_read: false)

    reply2 = Message.create!(
      author: @admin,
      parent: root,
      subject: "Re: Thread with replies",
      message: "Second reply",
      reply_mode: :reply_to_all
    )
    reply2_recipient = MessageRecipient.create!(message: reply2, recipient: @staff, is_read: false)

    query = <<~GQL
      query($messageId: ID!) {
        messageThread(messageId: $messageId) {
          id
          replies {
            id
          }
        }
      }
    GQL

    execute_graphql(query, variables: { messageId: root.id.to_s }, context: { current_user: @staff })

    assert root_recipient.reload.is_read, "Root message should be marked as read"
    assert reply1_recipient.reload.is_read, "First reply should be marked as read"
    assert reply2_recipient.reload.is_read, "Second reply should be marked as read"
  end

  test "message thread returns nil for non-existent message" do
    query = <<~GQL
      query($messageId: ID!) {
        messageThread(messageId: $messageId) {
          id
        }
      }
    GQL

    result = execute_graphql(query, variables: { messageId: "99999" }, context: { current_user: @staff })
    assert_nil result.dig("data", "messageThread")
  end

  # messageableUsers tests

  test "admin can message all users" do
    query = <<~GQL
      query {
        messageableUsers {
          id
          email
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @admin })
    users = result.dig("data", "messageableUsers")

    assert users.length >= 2
    emails = users.map { |u| u["email"] }
    assert_includes emails, @staff.email
    assert_includes emails, @mentor.email
  end

  test "mentor can only message their mentees" do
    mentee = create_mentee_user(email: "my_mentee@example.com", mentor: @mentor.mentor)
    other_mentee = create_mentee_user(email: "other_mentee@example.com")

    query = <<~GQL
      query {
        messageableUsers {
          id
          email
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @mentor })
    users = result.dig("data", "messageableUsers")

    emails = users.map { |u| u["email"] }
    assert_includes emails, mentee.email
    assert_not_includes emails, other_mentee.email
  end

  test "messageable users requires authentication" do
    query = <<~GQL
      query {
        messageableUsers {
          id
        }
      }
    GQL

    result = execute_graphql(query, context: {})
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
