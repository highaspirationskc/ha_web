require "application_system_test_case"

class RewardsSystemTest < ApplicationSystemTestCase
  def setup
    @admin = create_user(email: "sys_admin@example.com")
    Staff.create!(user: @admin, permission_level: :admin)

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
    event_type = EventType.create!(name: "Test Event", category: "org", point_value: 50)
    event = Event.create!(name: "Points Event", event_date: Time.current, event_type: event_type, created_by: @admin)
    EventLog.create!(user: @mentee_user, event: event, points_awarded: 50)

    @incentive = Incentive.create!(
      name: "Test Gift Card",
      description: "$25",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )

    @team_incentive = Incentive.create!(
      name: "Team Pizza",
      description: "Pizza party",
      point_cost: 100,
      incentive_type: "team",
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

  test "mentee sees rewards navigation" do
    login_as(@mentee_user)
    assert_link "Rewards"
  end

  test "mentee browses rewards page" do
    login_as(@mentee_user)
    click_link "Rewards"

    assert_selector "h1", text: /Rewards/i, wait: 5
    assert_text "Points: 50"
    assert_text "Test Gift Card"
    assert_text "25 pts"
  end

  test "mentee clicks individual tab" do
    login_as(@mentee_user)
    visit rewards_path

    assert_text "Test Gift Card"
    assert_no_text "Team Pizza" # Initially on individual tab
  end

  test "mentee clicks team tab" do
    login_as(@mentee_user)
    visit rewards_path

    click_on "Team"
    assert_text "Team Pizza"
    assert_no_text "Test Gift Card"
  end

  test "mentee clicks my redemptions tab" do
    # Create existing redemption
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    login_as(@mentee_user)
    visit rewards_path

    click_on "My Redemptions"
    assert_text "Test Gift Card"
    assert_text "Pending"
  end

  test "mentee clicks redeem and sees modal" do
    login_as(@mentee_user)
    visit rewards_path

    click_button "Redeem", match: :first
    assert_text "Test Gift Card", wait: 5
    assert_text "25 pts"
    assert_button "Redeem"
    assert_button "Cancel"
  end

  test "mentee creates redemption successfully" do
    login_as(@mentee_user)
    visit rewards_path

    assert_difference "Redemption.count", 1 do
      click_button "Redeem", match: :first
      click_button "Redeem", match: :first # Confirm in modal
      assert_text "Request submitted", wait: 5
    end

    redemption = Redemption.last
    assert_equal "pending", redemption.status
    assert_equal @mentee, redemption.mentee
    assert_equal @incentive, redemption.incentive
  end

  test "mentee sees redemption in my redemptions after creation" do
    login_as(@mentee_user)
    visit rewards_path

    click_button "Redeem", match: :first
    click_button "Redeem", match: :first
    assert_text "Request submitted", wait: 5

    click_on "My Redemptions"
    assert_text "Test Gift Card"
    assert_text "Pending"
  end

  test "mentee sees insufficient points message" do
    # Create expensive incentive
    Incentive.create!(
      name: "Expensive Item",
      description: "Costs 100 pts",
      point_cost: 100,
      incentive_type: "individual",
      created_by: @admin
    )

    login_as(@mentee_user)
    visit rewards_path

    # Try to redeem expensive item
    find(".incentive-card", text: "Expensive Item").click_button("Redeem")
    click_button "Redeem", match: :first

    assert_text "Insufficient points", wait: 5
  end

  test "mentee cannot access rewards as staff" do
    staff_user = create_staff_user(email: "staff_test@example.com")
    login_as(staff_user)
    visit rewards_path

    assert_text "Access denied", wait: 5
  end

  test "cancel modal closes without creating redemption" do
    login_as(@mentee_user)
    visit rewards_path

    assert_no_difference "Redemption.count" do
      click_button "Redeem", match: :first
      click_button "Cancel"
      assert_no_text "Test Gift Card", wait: 2 # Modal closed
    end
  end

  test "approved redemption shows approved status" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "approved",
      approved_by: @admin,
      approved_at: Time.current
    )

    login_as(@mentee_user)
    visit rewards_path
    click_on "My Redemptions"

    assert_text "Test Gift Card"
    assert_text "Approved"
    assert_text @admin.email
  end

  test "denied redemption shows denied status" do
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "denied",
      approved_by: @admin,
      notes: "Not enough documentation"
    )

    login_as(@mentee_user)
    visit rewards_path
    click_on "My Redemptions"

    assert_text "Test Gift Card"
    assert_text "Denied"
  end

  test "empty state when no redemptions" do
    # Ensure no redemptions exist
    @mentee.redemptions.destroy_all

    login_as(@mentee_user)
    visit rewards_path
    click_on "My Redemptions"

    assert_text "No redemptions yet"
  end
end
