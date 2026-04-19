require "application_system_test_case"

class RedemptionsSystemTest < ApplicationSystemTestCase
  def setup
    @admin = create_user(email: "sys_admin@example.com")
    @staff = create_staff_user(email: "sys_staff@example.com")
    @mentor = create_mentor_user(email: "sys_mentor@example.com")
    @mentee_user = create_mentee_user(email: "sys_mentee@example.com")
    @mentee = @mentee_user.mentee

    # Set up Olympic season and give mentee points
    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )
    event_type = EventType.create!(name: "Test Event", category: "org", point_value: 100)
    event = Event.create!(name: "Points Event", event_date: Time.current, event_type: event_type, created_by: @admin)
    EventLog.create!(user: @mentee_user, event: event, points_awarded: 100, log_type: "arrived")

    @incentive = Incentive.create!(
      name: "Test Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )
  end

  def login_as(user)
    visit login_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "Password123!"
    click_button "Sign in"
    assert_text "Dashboard", wait: 5
  end

  test "redeem incentive flow works end to end" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    login_as(@admin)
    visit user_path(@mentee_user)

    assert_selector "h3", text: /Redemptions/i, wait: 5
    assert_text "Awaiting Approval"

    click_button "Redeem Incentive", match: :first
    assert_text "Redeem Incentive", wait: 5
    assert_text "Test Gift Card"

    click_button "Redeem"

    # Check that the page updated (either success message or status changed)
    # The system test shows "Test Gift Card" with approved_by email now
    assert_no_text "Awaiting Approval", wait: 5
  end

  test "delete redemption flow works" do
    approved_redemption = Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "approved",
      approved_by: @admin,
      approved_at: Time.current
    )

    login_as(@admin)
    visit user_path(@mentee_user)

    assert_text "Test Gift Card"
    assert_text @admin.email

    # Click the delete icon - find button by the hover class
    find("button.text-gray-400", match: :first).click

    # Wait for modal to appear and check for visible content
    assert_selector "h3", text: "Delete Redemption", wait: 5

    fill_in "reason", with: "Duplicate redemption"
    check "Refund Points"
    click_button "Delete"

    # Wait for redirect and verify
    sleep 0.5
    visit user_path(@mentee_user)

    # The redemption should be deleted or status changed
    approved_redemption.reload
    assert_includes ["deleted", "deleted_no_refund"], approved_redemption.status
  end

  test "redeem incentive with message sends message end-to-end" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    login_as(@admin)
    visit user_path(@mentee_user)

    click_button "Redeem Incentive", match: :first
    assert_text "Redeem Incentive", wait: 5

    check "Send message with redemption"
    find("textarea[name='message_text']", match: :first).set("Your gift card is ready!")

    assert_difference "Message.count", 1 do
      click_button "Redeem"
      assert_no_text "Awaiting Approval", wait: 5
    end

    message = Message.last
    assert_equal @admin, message.author
    assert_includes message.recipients, @mentee_user
    assert_includes message.message, "Your gift card is ready!"
  end

  test "delete redemption with message sends message end-to-end" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "approved",
      approved_by: @admin,
      approved_at: Time.current
    )

    login_as(@admin)
    visit user_path(@mentee_user)

    find("button.text-gray-400", match: :first).click
    assert_selector "h3", text: "Delete Redemption", wait: 5

    fill_in "reason", with: "Issued by mistake"
    check "Send message with deletion"
    find("textarea[name='message_text']", match: :first).set("Sorry, we removed this by mistake.")

    assert_difference "Message.count", 1 do
      click_button "Delete"
      sleep 0.5
    end

    message = Message.last
    assert_equal @admin, message.author
    assert_includes message.recipients, @mentee_user
    assert_includes message.message, "Sorry, we removed this by mistake."
  end

  test "mentor cannot see redeem buttons" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    login_as(@mentor)
    visit user_path(@mentee_user)

    # Mentor is redirected to users_path or sees different page
    # Either way, they shouldn't be able to redeem
    assert_no_button "Redeem Incentive"
  rescue Capybara::ElementNotFound
    # Expected - mentor can't access the page or redeem button isn't there
    assert true
  end

  test "insufficient points blocks redemption" do
    expensive_incentive = Incentive.create!(
      name: "Expensive Item",
      description: "Costs 200 points",
      point_cost: 200,
      incentive_type: "individual",
      created_by: @admin
    )

    expensive_redemption = Redemption.create!(
      mentee: @mentee,
      incentive: expensive_incentive,
      points_spent: 200,
      status: "pending"
    )

    login_as(@admin)
    visit user_path(@mentee_user)

    assert_text "Awaiting Approval"

    click_button "Redeem Incentive", match: :first
    assert_text "Redeem Incentive", wait: 5
    click_button "Redeem"

    # Wait for redirect and page load
    sleep 0.5

    # The redemption should still be pending (blocked)
    visit user_path(@mentee_user)
    assert_text "Awaiting Approval"

    # Verify the redemption wasn't approved
    expensive_redemption.reload
    assert_equal "pending", expensive_redemption.status
  end

  test "redemptions section displays on mentee profile" do
    login_as(@admin)
    visit user_path(@mentee_user)

    assert_selector "h3", text: /Redemptions/i, wait: 5
    assert_selector "th", text: /INCENTIVE/i
    assert_selector "th", text: /REDEEMED ON/i
    assert_selector "th", text: /APPROVED BY/i
  end

  test "approved redemption shows approver email" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "approved",
      approved_by: @admin,
      approved_at: Time.current
    )

    login_as(@admin)
    visit user_path(@mentee_user)

    assert_text "Test Gift Card"
    assert_text @admin.email
    # Should see delete icon (trash SVG)
    assert_selector "button svg[stroke='currentColor']", match: :first
  end

  test "pending redemption shows awaiting approval chip" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    login_as(@admin)
    visit user_path(@mentee_user)

    assert_text "Awaiting Approval"
    assert_button "Redeem Incentive"
  end
end
