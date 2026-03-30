require "test_helper"

class RedemptionCreatedMessageTest < ActiveSupport::TestCase
  def setup
    # Create users (test helpers create role profiles automatically)
    @admin = create_user(email: "msg_admin@example.com")
    @staff = create_staff_user(email: "msg_staff@example.com")
    @mentee_user = create_mentee_user(email: "msg_mentee@example.com")
    @mentee = @mentee_user.mentee

    @incentive = Incentive.create!(
      name: "Jack Stack Gift Card",
      description: "$25 BBQ gift card",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )

    @redemption = Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    @message = RedemptionCreatedMessage.new(@redemption)
  end

  test "has correct subject" do
    assert_equal "New Redemption Request: Jack Stack Gift Card", @message.subject
  end

  test "body includes mentee name or email" do
    # Mentee may have first/last name or just email
    mentee_identifier = if @mentee_user.first_name.present? || @mentee_user.last_name.present?
      "#{@mentee_user.first_name} #{@mentee_user.last_name}".strip
    else
      @mentee_user.email
    end
    assert_includes @message.body, mentee_identifier
  end

  test "body includes incentive name" do
    assert_includes @message.body, "Jack Stack Gift Card"
  end

  test "body includes point cost" do
    assert_includes @message.body, "25"
  end

  test "body includes link to mentee profile" do
    # The body should contain an HTML link
    assert_match %r{<a href="/users/\d+"}, @message.body
    assert_includes @message.body, "Review this redemption</a>"
  end

  test "recipients are staff with manage_redemptions permission" do
    recipients = @message.recipients
    assert_includes recipients, @admin
    assert_includes recipients, @staff
    assert_not_includes recipients, @mentee_user
  end

  test "marked as support message" do
    assert @message.support?
  end

  test "reply mode is reply_to_sender" do
    assert_equal :reply_to_sender, @message.reply_mode
  end

  test "deliver creates message" do
    assert_difference "Message.count", 1 do
      @message.deliver
    end

    message = Message.last
    assert_equal "New Redemption Request: Jack Stack Gift Card", message.subject
    assert message.support
  end

  test "deliver creates message recipients for all staff" do
    assert_difference "MessageRecipient.count", 2 do
      @message.deliver
    end
  end

  test "handles mentee with no first/last name" do
    @mentee_user.update!(first_name: nil, last_name: nil)
    @message = RedemptionCreatedMessage.new(@redemption)

    assert_includes @message.body, @mentee_user.email
  end

  test "includes current mentee point balance" do
    # Set up Olympic season and give mentee points
    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )
    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 100)
    event = Event.create!(name: "Points Event", event_date: Time.current, event_type: event_type, created_by: @admin)
    EventLog.create!(user: @mentee_user, event: event, points_awarded: 100, log_type: "arrived")

    # Create a new redemption (the setup one already exists and deducts 25 points)
    # With 100 points earned - 25 points spent (from setup redemption) = 75 points
    @message = RedemptionCreatedMessage.new(@redemption)
    assert_includes @message.body, "75"
  end
end
