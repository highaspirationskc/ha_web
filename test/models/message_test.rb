require "test_helper"

class MessageTest < ActiveSupport::TestCase
  def setup
    @sender = create_user(email: "sender@example.com")
    @recipient = create_mentee_user(email: "recipient@example.com")
  end

  test "valid message" do
    message = Message.new(
      author: @sender,
      subject: "Test Subject",
      message: "Test message body"
    )
    assert message.valid?
  end

  test "requires author" do
    message = Message.new(
      subject: "Test Subject",
      message: "Test message body"
    )
    assert_not message.valid?
    assert_includes message.errors[:author], "must exist"
  end

  test "requires subject" do
    message = Message.new(
      author: @sender,
      message: "Test message body"
    )
    assert_not message.valid?
    assert_includes message.errors[:subject], "can't be blank"
  end

  test "requires message body" do
    message = Message.new(
      author: @sender,
      subject: "Test Subject"
    )
    assert_not message.valid?
    assert_includes message.errors[:message], "can't be blank"
  end

  test "can have multiple recipients" do
    recipient2 = create_mentor_user(email: "recipient2@example.com")

    message = Message.create!(
      author: @sender,
      subject: "Test Subject",
      message: "Test message body"
    )
    message.recipients << @recipient
    message.recipients << recipient2

    assert_equal 2, message.recipients.count
    assert_includes message.recipients, @recipient
    assert_includes message.recipients, recipient2
  end

  test "sender can access sent messages" do
    message = Message.create!(
      author: @sender,
      subject: "Test Subject",
      message: "Test message body"
    )
    assert_includes @sender.sent_messages, message
  end

  test "recipient can access received messages" do
    message = Message.create!(
      author: @sender,
      subject: "Test Subject",
      message: "Test message body"
    )
    message.recipients << @recipient

    assert_includes @recipient.received_messages, message
  end

  test "recent scope orders by created_at desc" do
    old_message = Message.create!(
      author: @sender,
      subject: "Old",
      message: "Old message",
      created_at: 2.days.ago
    )
    new_message = Message.create!(
      author: @sender,
      subject: "New",
      message: "New message"
    )

    assert_equal new_message, Message.recent.first
    assert_equal old_message, Message.recent.last
  end

  test "roots scope returns only messages without parent" do
    root_message = Message.create!(
      author: @sender,
      subject: "Root",
      message: "Root message"
    )
    reply = Message.create!(
      author: @recipient,
      parent: root_message,
      subject: "Re: Root",
      message: "Reply message"
    )

    assert_includes Message.roots, root_message
    assert_not_includes Message.roots, reply
  end

  test "reply? returns true for replies" do
    root_message = Message.create!(
      author: @sender,
      subject: "Root",
      message: "Root message"
    )
    reply = Message.create!(
      author: @recipient,
      parent: root_message,
      subject: "Re: Root",
      message: "Reply message"
    )

    assert_not root_message.reply?
    assert reply.reply?
  end

  test "thread_root returns root message" do
    root_message = Message.create!(
      author: @sender,
      subject: "Root",
      message: "Root message"
    )
    reply = Message.create!(
      author: @recipient,
      parent: root_message,
      subject: "Re: Root",
      message: "Reply message"
    )
    nested_reply = Message.create!(
      author: @sender,
      parent: reply,
      subject: "Re: Re: Root",
      message: "Nested reply"
    )

    assert_equal root_message, root_message.thread_root
    assert_equal root_message, reply.thread_root
    assert_equal root_message, nested_reply.thread_root
  end

  test "replies association returns direct replies" do
    root_message = Message.create!(
      author: @sender,
      subject: "Root",
      message: "Root message"
    )
    reply1 = Message.create!(
      author: @recipient,
      parent: root_message,
      subject: "Re: Root",
      message: "Reply 1"
    )
    reply2 = Message.create!(
      author: @recipient,
      parent: root_message,
      subject: "Re: Root",
      message: "Reply 2"
    )

    assert_equal 2, root_message.replies.count
    assert_includes root_message.replies, reply1
    assert_includes root_message.replies, reply2
  end
end
