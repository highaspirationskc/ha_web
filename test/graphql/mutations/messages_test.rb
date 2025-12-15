require "test_helper"

class MessagesMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin@example.com")
    @staff = create_staff_user(email: "staff@example.com")
    @mentor = create_mentor_user(email: "mentor@example.com")
    @mentee_user = create_mentee_user(email: "mentee@example.com", mentor: @mentor.mentor)
  end

  # ComposeMessage tests

  test "authenticated user can compose message" do
    mutation = <<~GQL
      mutation($input: ComposeMessageInput!) {
        composeMessage(input: $input) {
          message {
            id
            subject
            message
            replyMode
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        subject: "Test Subject",
        message: "Test message body",
        recipientIds: [@staff.id.to_s]
      }
    }, context: { current_user: @admin })

    message = result.dig("data", "composeMessage", "message")
    errors = result.dig("data", "composeMessage", "errors")

    assert_not_nil message
    assert_equal "Test Subject", message["subject"]
    assert_equal "Test message body", message["message"]
    assert_equal "reply_to_sender", message["replyMode"]
    assert_empty errors
  end

  test "compose message with reply_to_all mode" do
    mutation = <<~GQL
      mutation($input: ComposeMessageInput!) {
        composeMessage(input: $input) {
          message {
            id
            replyMode
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        subject: "Group Message",
        message: "Message to everyone",
        recipientIds: [@staff.id.to_s],
        replyMode: "reply_to_all"
      }
    }, context: { current_user: @admin })

    message = result.dig("data", "composeMessage", "message")
    assert_equal "reply_to_all", message["replyMode"]
  end

  test "compose message requires authentication" do
    mutation = <<~GQL
      mutation($input: ComposeMessageInput!) {
        composeMessage(input: $input) {
          message {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        subject: "Test",
        message: "Test",
        recipientIds: [@staff.id.to_s]
      }
    }, context: {})

    assert_nil result.dig("data", "composeMessage")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  test "compose message requires at least one recipient" do
    mutation = <<~GQL
      mutation($input: ComposeMessageInput!) {
        composeMessage(input: $input) {
          message {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        subject: "Test",
        message: "Test",
        recipientIds: []
      }
    }, context: { current_user: @admin })

    errors = result.dig("data", "composeMessage", "errors")
    assert_includes errors, "At least one recipient is required"
  end

  test "mentor cannot compose message to unauthorized recipient" do
    other_mentor = create_mentor_user(email: "other_mentor@example.com")

    mutation = <<~GQL
      mutation($input: ComposeMessageInput!) {
        composeMessage(input: $input) {
          message {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        subject: "Test",
        message: "Test",
        recipientIds: [other_mentor.id.to_s]
      }
    }, context: { current_user: @mentor })

    errors = result.dig("data", "composeMessage", "errors")
    assert errors.first.include?("not authorized to message")
  end

  # ReplyMessage tests

  test "can reply to message in thread" do
    original = Message.create!(
      author: @admin,
      subject: "Original",
      message: "Original message",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: original, recipient: @staff)

    mutation = <<~GQL
      mutation($input: ReplyMessageInput!) {
        replyMessage(input: $input) {
          message {
            id
            subject
            message
            isReply
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        parentId: original.id.to_s,
        message: "This is my reply"
      }
    }, context: { current_user: @staff })

    message = result.dig("data", "replyMessage", "message")
    errors = result.dig("data", "replyMessage", "errors")

    assert_not_nil message
    assert_equal "Re: Original", message["subject"]
    assert_equal "This is my reply", message["message"]
    assert message["isReply"]
    assert_empty errors
  end

  test "cannot reply to message not in thread" do
    original = Message.create!(
      author: @admin,
      subject: "Original",
      message: "Original message",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: original, recipient: @staff)

    mutation = <<~GQL
      mutation($input: ReplyMessageInput!) {
        replyMessage(input: $input) {
          message {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        parentId: original.id.to_s,
        message: "Unauthorized reply"
      }
    }, context: { current_user: @mentor })

    errors = result.dig("data", "replyMessage", "errors")
    assert_includes errors, "You are not authorized to reply to this message"
  end

  test "cannot reply to message with no_replies mode" do
    original = Message.create!(
      author: @admin,
      subject: "No Reply",
      message: "Cannot reply to this",
      reply_mode: :no_replies
    )
    MessageRecipient.create!(message: original, recipient: @staff)

    mutation = <<~GQL
      mutation($input: ReplyMessageInput!) {
        replyMessage(input: $input) {
          message {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        parentId: original.id.to_s,
        message: "Attempted reply"
      }
    }, context: { current_user: @staff })

    errors = result.dig("data", "replyMessage", "errors")
    assert_includes errors, "Replies are not allowed for this message"
  end

  # MarkThreadRead tests

  test "can mark thread as read" do
    original = Message.create!(
      author: @admin,
      subject: "Unread",
      message: "Please read me",
      reply_mode: :reply_to_sender
    )
    recipient = MessageRecipient.create!(message: original, recipient: @staff, is_read: false)

    mutation = <<~GQL
      mutation($messageId: ID!) {
        markThreadRead(messageId: $messageId) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      messageId: original.id.to_s
    }, context: { current_user: @staff })

    success = result.dig("data", "markThreadRead", "success")
    errors = result.dig("data", "markThreadRead", "errors")

    assert success
    assert_empty errors
    assert recipient.reload.is_read
  end

  test "mark thread read returns error for non-existent message" do
    mutation = <<~GQL
      mutation($messageId: ID!) {
        markThreadRead(messageId: $messageId) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      messageId: "99999"
    }, context: { current_user: @admin })

    success = result.dig("data", "markThreadRead", "success")
    errors = result.dig("data", "markThreadRead", "errors")

    assert_not success
    assert_includes errors, "Message not found"
  end

  # ArchiveMessage tests

  test "can archive message" do
    original = Message.create!(
      author: @admin,
      subject: "Archive Me",
      message: "Archive this message",
      reply_mode: :reply_to_sender
    )
    recipient = MessageRecipient.create!(message: original, recipient: @staff, archived: false)

    mutation = <<~GQL
      mutation($messageId: ID!) {
        archiveMessage(messageId: $messageId) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      messageId: original.id.to_s
    }, context: { current_user: @staff })

    success = result.dig("data", "archiveMessage", "success")
    errors = result.dig("data", "archiveMessage", "errors")

    assert success
    assert_empty errors
    assert recipient.reload.archived
  end

  test "can unarchive message" do
    original = Message.create!(
      author: @admin,
      subject: "Unarchive Me",
      message: "Unarchive this message",
      reply_mode: :reply_to_sender
    )
    recipient = MessageRecipient.create!(message: original, recipient: @staff, archived: true)

    mutation = <<~GQL
      mutation($messageId: ID!, $archive: Boolean!) {
        archiveMessage(messageId: $messageId, archive: $archive) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      messageId: original.id.to_s,
      archive: false
    }, context: { current_user: @staff })

    success = result.dig("data", "archiveMessage", "success")
    assert success
    assert_not recipient.reload.archived
  end

  test "archive message returns error if not recipient" do
    original = Message.create!(
      author: @admin,
      subject: "Not Your Message",
      message: "You are not a recipient",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: original, recipient: @staff)

    mutation = <<~GQL
      mutation($messageId: ID!) {
        archiveMessage(messageId: $messageId) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      messageId: original.id.to_s
    }, context: { current_user: @mentor })

    errors = result.dig("data", "archiveMessage", "errors")
    assert_includes errors, "You are not a recipient of this thread"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
