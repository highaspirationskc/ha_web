require "test_helper"

class MenteeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "mentee@example.com",
      password: "Password123!"
    )
    @team = Team.create!(name: "Test Team", color: "#3B82F6")
    @mentee = Mentee.new(user: @user, team: @team)
  end

  # Associations
  test "belongs to user" do
    assert_respond_to @mentee, :user
    assert_equal @user, @mentee.user
  end

  test "belongs to team (optional)" do
    assert_respond_to @mentee, :team
    assert_equal @team, @mentee.team
  end

  test "belongs to mentor (optional)" do
    assert_respond_to @mentee, :mentor
  end

  test "has many family_members" do
    assert_respond_to @mentee, :family_members
  end

  test "has many guardians through family_members" do
    assert_respond_to @mentee, :guardians
  end

  # Validations
  test "is valid with a user" do
    assert @mentee.valid?
  end

  test "is invalid without a user" do
    @mentee.user = nil
    assert_not @mentee.valid?
    assert_includes @mentee.errors[:user], "must exist"
  end

  test "is valid without a team" do
    @mentee.team = nil
    assert @mentee.valid?
  end

  test "is valid without a mentor" do
    @mentee.mentor = nil
    assert @mentee.valid?
  end

  # Mentor relationship
  test "can be assigned to a mentor" do
    mentor_user = User.create!(email: "mentor@example.com", password: "Password123!")
    mentor = Mentor.create!(user: mentor_user)

    @mentee.mentor = mentor
    @mentee.save!

    assert_equal mentor, @mentee.mentor
  end

  # Guardian relationships
  test "can have multiple guardians" do
    @mentee.save!

    guardian_user1 = User.create!(email: "guardian1@example.com", password: "Password123!")
    guardian_user2 = User.create!(email: "guardian2@example.com", password: "Password123!")

    guardian1 = Guardian.create!(user: guardian_user1)
    guardian2 = Guardian.create!(user: guardian_user2)

    FamilyMember.create!(guardian: guardian1, mentee: @mentee, relationship_type: "parent")
    FamilyMember.create!(guardian: guardian2, mentee: @mentee, relationship_type: "grandparent")

    assert_includes @mentee.guardians, guardian1
    assert_includes @mentee.guardians, guardian2
    assert_equal 2, @mentee.guardians.count
  end

  # Team relationship
  test "can be assigned to a team" do
    new_team = Team.create!(name: "New Team", color: "#E11D48")
    @mentee.team = new_team
    @mentee.save!

    assert_equal new_team, @mentee.team
  end

  # Total points
  test "total_points returns 0 when no event logs exist" do
    @mentee.save!
    assert_equal 0, @mentee.total_points
  end

  test "total_points returns 0 when no current season exists" do
    @mentee.save!
    OlympicSeason.delete_all

    assert_equal 0, @mentee.total_points
  end

  test "total_points sums points from event logs within current season" do
    @mentee.save!

    # Create a current season (month/day based)
    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Test Event Type", category: "org", point_value: 10)
    event = Event.create!(
      name: "Test Event",
      event_date: Time.current,
      event_type: event_type,
      created_by: @user
    )

    # Create event logs for this mentee's user
    EventLog.create!(user: @user, event: event, points_awarded: 10)
    EventLog.create!(user: @user, event: event, points_awarded: 5)

    assert_equal 15, @mentee.total_points
  end

  test "total_points excludes points from events outside current season" do
    @mentee.save!

    # Create a current season (month/day based)
    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Test Event Type", category: "org", point_value: 10)

    # Event within season
    current_event = Event.create!(
      name: "Current Event",
      event_date: Time.current,
      event_type: event_type,
      created_by: @user
    )

    # Event outside season
    old_event = Event.create!(
      name: "Old Event",
      event_date: 3.months.ago,
      event_type: event_type,
      created_by: @user
    )

    EventLog.create!(user: @user, event: current_event, points_awarded: 10)
    EventLog.create!(user: @user, event: old_event, points_awarded: 100)

    assert_equal 10, @mentee.total_points
  end

  test "total_points accepts custom date range" do
    @mentee.save!

    event_type = EventType.create!(name: "Test Event Type", category: "org", point_value: 10)

    event1 = Event.create!(
      name: "Event 1",
      event_date: 2.days.ago,
      event_type: event_type,
      created_by: @user
    )

    event2 = Event.create!(
      name: "Event 2",
      event_date: 10.days.ago,
      event_type: event_type,
      created_by: @user
    )

    EventLog.create!(user: @user, event: event1, points_awarded: 5)
    EventLog.create!(user: @user, event: event2, points_awarded: 20)

    # Only include last week
    week_range = 1.week.ago..Time.current
    assert_equal 5, @mentee.total_points(week_range)
  end

  # Total points with redemption deductions
  test "total_points deducts pending redemptions" do
    @mentee.save!
    admin = create_user(email: "pts_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    incentive = Incentive.create!(name: "Gift Card", point_cost: 20, created_by: admin)
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 20, status: "pending")

    assert_equal 30, @mentee.total_points
  end

  test "total_points deducts approved redemptions" do
    @mentee.save!
    admin = create_user(email: "pts_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    incentive = Incentive.create!(name: "Gift Card", point_cost: 20, created_by: admin)
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 20, status: "approved", approved_by: admin)

    assert_equal 30, @mentee.total_points
  end

  test "total_points restores points for denied redemptions" do
    @mentee.save!
    admin = create_user(email: "pts_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    incentive = Incentive.create!(name: "Gift Card", point_cost: 20, created_by: admin)
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 20, status: "denied")

    assert_equal 50, @mentee.total_points
  end

  test "total_points restores points for deleted (refunded) redemptions" do
    @mentee.save!
    admin = create_user(email: "pts_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    incentive = Incentive.create!(name: "Gift Card", point_cost: 20, created_by: admin)
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 20, status: "deleted")

    assert_equal 50, @mentee.total_points
  end

  test "total_points keeps points deducted for deleted_no_refund redemptions" do
    @mentee.save!
    admin = create_user(email: "pts_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    incentive = Incentive.create!(name: "Gift Card", point_cost: 20, created_by: admin)
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 20, status: "deleted_no_refund")

    assert_equal 30, @mentee.total_points
  end

  test "total_points deducts multiple active redemptions" do
    @mentee.save!
    admin = create_user(email: "pts_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    incentive = Incentive.create!(name: "Gift Card", point_cost: 10, created_by: admin)
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 10, status: "pending")
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 10, status: "approved")
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 10, status: "denied")

    assert_equal 30, @mentee.total_points
  end

  # Community Service Hours
  test "has many community_service_records" do
    @mentee.save!
    assert_respond_to @mentee, :community_service_records
  end

  test "total_community_service_hours returns 0 when no records exist" do
    @mentee.save!
    assert_equal 0, @mentee.total_community_service_hours
  end

  test "total_community_service_hours returns 0 when no current season exists" do
    @mentee.save!
    OlympicSeason.delete_all

    assert_equal 0, @mentee.total_community_service_hours
  end

  test "total_community_service_hours sums approved hours within current season" do
    @mentee.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    CommunityServiceRecord.create!(mentee: @mentee, event: "Event 1", event_date: Date.current, hours: 2.5)
    CommunityServiceRecord.create!(mentee: @mentee, event: "Event 2", event_date: Date.current, hours: 1.5)

    assert_equal 4.0, @mentee.total_community_service_hours
  end

  test "total_community_service_hours excludes denied records" do
    @mentee.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    CommunityServiceRecord.create!(mentee: @mentee, event: "Approved", event_date: Date.current, hours: 3.0, approved: true)
    CommunityServiceRecord.create!(mentee: @mentee, event: "Denied", event_date: Date.current, hours: 10.0, approved: false)

    assert_equal 3.0, @mentee.total_community_service_hours
  end

  test "total_community_service_hours excludes records outside current season" do
    @mentee.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    CommunityServiceRecord.create!(mentee: @mentee, event: "Current", event_date: Date.current, hours: 2.0)
    CommunityServiceRecord.create!(mentee: @mentee, event: "Old", event_date: 3.months.ago.to_date, hours: 50.0)

    assert_equal 2.0, @mentee.total_community_service_hours
  end

  test "total_community_service_hours accepts custom date range" do
    @mentee.save!

    CommunityServiceRecord.create!(mentee: @mentee, event: "Recent", event_date: 2.days.ago.to_date, hours: 1.5)
    CommunityServiceRecord.create!(mentee: @mentee, event: "Older", event_date: 10.days.ago.to_date, hours: 5.0)

    week_range = 1.week.ago.to_date..Date.current
    assert_equal 1.5, @mentee.total_community_service_hours(week_range)
  end

  # can_afford? tests
  test "can_afford? returns true when mentee has sufficient points" do
    @mentee.save!
    create_user(email: "afford_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    assert @mentee.can_afford?(30)
  end

  test "can_afford? returns false when mentee has insufficient points" do
    @mentee.save!
    admin = create_user(email: "afford_admin2@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    incentive = Incentive.create!(name: "Gift Card", point_cost: 30, created_by: admin)
    Redemption.create!(mentee: @mentee, incentive: incentive, points_spent: 30, status: "approved", approved_by: admin)

    assert_not @mentee.can_afford?(25)
  end

  test "can_afford? returns true when mentee has exactly enough points" do
    @mentee.save!
    create_user(email: "afford_admin3@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    event_type = EventType.create!(name: "Point Event", category: "org", point_value: 50)
    event = Event.create!(name: "Big Event", event_date: Time.current, event_type: event_type, created_by: @user)
    EventLog.create!(user: @user, event: event, points_awarded: 50)

    assert @mentee.can_afford?(50)
  end
end
