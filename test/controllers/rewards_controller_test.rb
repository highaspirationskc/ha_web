require "test_helper"

class RewardsControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create users (test helpers create role profiles automatically)
    @admin = create_user(email: "rewards_admin@example.com")
    @staff = create_staff_user(email: "rewards_staff@example.com")
    @mentor = create_mentor_user(email: "rewards_mentor@example.com")
    @mentee_user = create_mentee_user(email: "rewards_mentee@example.com")
    @mentee = @mentee_user.mentee

    # Create test incentive
    @incentive = Incentive.create!(
      name: "Test Gift Card",
      description: "$25 gift card",
      point_cost: 25,
      incentive_type: "individual",
      created_by: @admin
    )

    # Create team incentive
    @team_incentive = Incentive.create!(
      name: "Team Pizza Party",
      description: "Pizza for the team",
      point_cost: 100,
      incentive_type: "team",
      created_by: @admin
    )
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # Authentication tests
  test "rewards route requires authentication" do
    get rewards_path
    assert_redirected_to root_path
  end

  test "rewards route returns 200 for authenticated mentee" do
    login_as(@mentee_user)
    get rewards_path
    assert_response :success
  end

  # Authorization tests
  test "rewards redirects to dashboard for staff" do
    login_as(@staff)
    get rewards_path
    assert_redirected_to dashboard_path
  end

  test "rewards redirects to dashboard for admin" do
    login_as(@admin)
    get rewards_path
    assert_redirected_to dashboard_path
  end

  test "rewards redirects to dashboard for mentor" do
    login_as(@mentor)
    get rewards_path
    assert_redirected_to dashboard_path
  end

  # Content tests
  test "index returns incentives" do
    login_as(@mentee_user)
    get rewards_path
    assert_response :success
    assert_select "h1", /Rewards/i
    assert_select ".incentive-card", count: 2 # Both individual and team should appear
  end

  test "index shows individual incentives tab" do
    login_as(@mentee_user)
    get rewards_path
    assert_response :success
    assert_select "[data-tab='individual']", /Individual/i
  end

  test "index shows team incentives tab" do
    login_as(@mentee_user)
    get rewards_path
    assert_response :success
    assert_select "[data-tab='team']", /Team/i
  end

  test "index shows my redemptions tab" do
    login_as(@mentee_user)
    get rewards_path
    assert_response :success
    assert_select "[data-tab='my-redemptions']", /My Redemptions/i
  end

  test "index displays points available" do
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

    login_as(@mentee_user)
    get rewards_path
    assert_response :success
    assert_select ".points-display", /Points: 50/
  end

  test "index shows redemption history" do
    # Create some redemptions
    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "pending"
    )

    Redemption.create!(
      mentee: @mentee,
      incentive: @incentive,
      points_spent: 25,
      status: "approved",
      approved_by: @admin,
      approved_at: Time.current
    )

    login_as(@mentee_user)
    get rewards_path
    assert_response :success
    assert_select ".redemption-item", count: 2
    assert_select ".status-pending", /Pending/i
    assert_select ".status-approved", /Approved/i
  end

  test "index does not show inactive incentives" do
    Incentive.create!(
      name: "Inactive Item",
      description: "Not available",
      point_cost: 10,
      incentive_type: "individual",
      active: false,
      created_by: @admin
    )

    login_as(@mentee_user)
    get rewards_path
    assert_response :success
    assert_select ".incentive-card", count: 2 # Only active incentives
  end
end
