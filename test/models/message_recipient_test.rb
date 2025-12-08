require "test_helper"

class MessageRecipientTest < ActiveSupport::TestCase
  def setup
    @sender = create_user(email: "sender@example.com")
    @recipient = create_mentee_user(email: "recipient@example.com")
    @message = Message.create!(
      author: @sender,
      subject: "Test Subject",
      message: "Test message body"
    )
  end

  test "valid message recipient" do
    message_recipient = MessageRecipient.new(
      message: @message,
      recipient: @recipient
    )
    assert message_recipient.valid?
  end

  test "requires message" do
    message_recipient = MessageRecipient.new(
      recipient: @recipient
    )
    assert_not message_recipient.valid?
    assert_includes message_recipient.errors[:message], "must exist"
  end

  test "requires recipient" do
    message_recipient = MessageRecipient.new(
      message: @message
    )
    assert_not message_recipient.valid?
    assert_includes message_recipient.errors[:recipient], "must exist"
  end

  test "is_read defaults to false" do
    message_recipient = MessageRecipient.create!(
      message: @message,
      recipient: @recipient
    )
    assert_equal false, message_recipient.is_read
  end

  test "mark_as_read! sets is_read to true" do
    message_recipient = MessageRecipient.create!(
      message: @message,
      recipient: @recipient
    )
    assert_not message_recipient.is_read?
    message_recipient.mark_as_read!
    assert message_recipient.is_read?
  end

  test "unread scope returns only unread recipients" do
    read_recipient = MessageRecipient.create!(
      message: @message,
      recipient: @recipient,
      is_read: true
    )

    other_recipient = create_mentor_user(email: "other@example.com")
    unread_recipient = MessageRecipient.create!(
      message: @message,
      recipient: other_recipient
    )

    assert_includes MessageRecipient.unread, unread_recipient
    assert_not_includes MessageRecipient.unread, read_recipient
  end

  test "read scope returns only read recipients" do
    read_recipient = MessageRecipient.create!(
      message: @message,
      recipient: @recipient,
      is_read: true
    )

    other_recipient = create_mentor_user(email: "other@example.com")
    unread_recipient = MessageRecipient.create!(
      message: @message,
      recipient: other_recipient
    )

    assert_includes MessageRecipient.read, read_recipient
    assert_not_includes MessageRecipient.read, unread_recipient
  end

  test "prevents duplicate recipient for same message" do
    MessageRecipient.create!(
      message: @message,
      recipient: @recipient
    )

    duplicate = MessageRecipient.new(
      message: @message,
      recipient: @recipient
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save!
    end
  end
end
