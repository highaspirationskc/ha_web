require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "admin@example.com")
    @staff = create_staff_user(email: "staff@example.com")
    @mentor = create_mentor_user(email: "mentor@example.com")
    @mentee = create_mentee_user(email: "mentee@example.com", mentor: @mentor.mentor)
    @guardian = create_guardian_user(email: "guardian@example.com")

    # Link guardian to mentee
    FamilyMember.create!(mentee: @mentee.mentee, guardian: @guardian.guardian, relationship_type: "parent")
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # Index tests
  test "should redirect to login when not authenticated" do
    get messages_path
    assert_redirected_to root_path
  end

  test "should show inbox when authenticated" do
    login_as(@admin)
    get messages_path
    assert_response :success
  end

  test "should show received messages in inbox" do
    message = Message.create!(author: @staff, subject: "Test", message: "Hello")
    message.recipients << @admin

    login_as(@admin)
    get messages_path
    assert_response :success
    assert_select "a", text: /Test/
  end

  # Show thread tests
  test "should show message thread" do
    message = Message.create!(author: @admin, subject: "Thread Test", message: "Hello")
    message.recipients << @staff

    login_as(@staff)
    get message_path(message)
    assert_response :success
  end

  test "should not show message if not recipient or author" do
    message = Message.create!(author: @admin, subject: "Secret", message: "Hello")
    message.recipients << @staff

    login_as(@mentor)
    get message_path(message)
    assert_redirected_to messages_path
  end

  test "should mark message as read when viewed" do
    message = Message.create!(author: @admin, subject: "Unread", message: "Hello")
    message.recipients << @staff

    login_as(@staff)
    assert_not message.message_recipients.find_by(recipient: @staff).is_read

    get message_path(message)

    assert message.message_recipients.find_by(recipient: @staff).reload.is_read
  end

  # New/compose tests
  test "should show compose form" do
    login_as(@admin)
    get new_message_path
    assert_response :success
  end

  # Create tests
  test "admin can send message to anyone" do
    login_as(@admin)

    assert_difference "Message.count", 1 do
      post messages_path, params: {
        message: {
          subject: "Admin message",
          message: "Hello from admin",
          recipient_ids: [@staff.id]
        }
      }
    end

    assert_redirected_to sent_messages_path
  end

  test "mentor can send message to their mentee" do
    login_as(@mentor)

    # Creates 2 messages: one to mentee, one CC to guardian
    assert_difference "Message.count", 2 do
      post messages_path, params: {
        message: {
          subject: "Mentor message",
          message: "Hello mentee",
          recipient_ids: [@mentee.id]
        }
      }
    end
  end

  test "mentor cannot send message to non-mentee" do
    other_mentee = create_mentee_user(email: "other@example.com")

    login_as(@mentor)

    assert_no_difference "Message.count" do
      post messages_path, params: {
        message: {
          subject: "Invalid message",
          message: "Should not send",
          recipient_ids: [other_mentee.id]
        }
      }
    end
  end

  test "mentee can send message to their mentor" do
    login_as(@mentee)

    assert_difference "Message.count", 1 do
      post messages_path, params: {
        message: {
          subject: "Mentee message",
          message: "Hello mentor",
          recipient_ids: [@mentor.id]
        }
      }
    end
  end

  test "mentee can send message to support" do
    login_as(@mentee)

    assert_difference "Message.count", 1 do
      post messages_path, params: {
        message: {
          subject: "Support request",
          message: "Need help",
          recipient_ids: ["support"]
        }
      }
    end

    message = Message.last
    assert message.support?
  end

  test "sending to mentee creates CC message for guardian" do
    login_as(@mentor)

    assert_difference "Message.count", 2 do
      post messages_path, params: {
        message: {
          subject: "Family message",
          message: "Hello",
          recipient_ids: [@mentee.id]
        }
      }
    end

    # Original message to mentee
    original = Message.find_by(subject: "Family message")
    assert_includes original.recipients, @mentee
    assert_not_includes original.recipients, @guardian

    # CC message to guardian
    cc_message = Message.find_by(subject: "cc: Family message")
    assert_not_nil cc_message
    assert_includes cc_message.recipients, @guardian
  end

  # Reply tests
  test "can reply to a message" do
    original = Message.create!(author: @admin, subject: "Original", message: "Hello")
    original.recipients << @staff

    login_as(@staff)

    assert_difference "Message.count", 1 do
      post messages_path, params: {
        message: {
          subject: "Re: Original",
          message: "Reply",
          parent_id: original.id,
          recipient_ids: [@admin.id]
        }
      }
    end

    reply = Message.last
    assert_equal original, reply.parent
  end

  # Support message tests
  test "support message adds all staff as recipients" do
    login_as(@mentee)

    assert_difference "Message.count", 1 do
      post messages_path, params: {
        message: {
          subject: "Support request",
          message: "Need help",
          recipient_ids: ["support"]
        }
      }
    end

    message = Message.last
    assert message.support?
    assert message.reply_to_all?
    assert_includes message.recipients, @staff
    assert_includes message.recipients, @admin
  end

  test "support messages appear in staff inbox" do
    message = Message.create!(author: @mentee, subject: "Help", message: "Need help", support: true)
    message.recipients << @staff

    login_as(@staff)
    get messages_path
    assert_response :success
    assert_select "span", text: "Support"
  end
end
