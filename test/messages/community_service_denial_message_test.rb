# frozen_string_literal: true

require "test_helper"

class CommunityServiceDenialMessageTest < ActiveSupport::TestCase
  def setup
    @staff = create_staff_user(email: "cs_denial_staff@example.com")
    @mentor = create_mentor_user(email: "cs_denial_mentor@example.com")
    @mentee_user = create_mentee_user(email: "cs_denial_mentee@example.com", mentor: @mentor.mentor)
    @record = CommunityServiceRecord.create!(
      mentee: @mentee_user.mentee,
      event: "Park Cleanup",
      description: "Cleaned up the park",
      event_date: Date.current,
      hours: 3.0
    )
  end

  test "delivers denial message with correct attributes" do
    result = CommunityServiceDenialMessage.new(@record, author: @staff, reason: "Insufficient documentation").deliver

    assert result.success?
    message = result.message
    assert_equal @staff, message.author
    assert_equal "Community Service Record Denied: Park Cleanup", message.subject
    assert_includes message.message, "Park Cleanup"
    assert_includes message.message, "Insufficient documentation"
    assert_includes message.message, @record.hours.to_s
    assert message.reply_to_sender?
    assert_not message.support?
    assert_includes message.recipients, @mentee_user
  end

  test "only sends to the mentee" do
    result = CommunityServiceDenialMessage.new(@record, author: @staff, reason: "Reason").deliver

    assert result.success?
    assert_equal 1, result.message.recipients.count
    assert_includes result.message.recipients, @mentee_user
  end
end
