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

  test "has many point_logs" do
    assert_respond_to @mentee, :point_logs
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
  test "total_points returns 0 when no point logs exist" do
    @mentee.save!
    assert_equal 0, @mentee.total_points
  end

  test "total_points returns 0 when no current season exists" do
    @mentee.save!
    OlympicSeason.delete_all

    assert_equal 0, @mentee.total_points
  end

  test "total_points sums points from point logs within current season" do
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

    admin_user = create_user(email: "admin@test.com")

    # Create point logs for this mentee within season
    PointLog.create!(mentee: @mentee, points: 10, reason: "Event 1", awarded_by: admin_user, log_type: "attendance")
    PointLog.create!(mentee: @mentee, points: 5, reason: "Event 2", awarded_by: admin_user, log_type: "attendance")

    assert_equal 15, @mentee.total_points
  end

  test "total_points excludes points from point logs outside current season" do
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

    admin_user = create_user(email: "admin@test.com")

    # Point log within season
    PointLog.create!(mentee: @mentee, points: 10, reason: "Current", awarded_by: admin_user, log_type: "attendance")

    # Point log outside season
    PointLog.create!(mentee: @mentee, points: 100, reason: "Old", awarded_by: admin_user, log_type: "attendance", created_at: 3.months.ago)

    assert_equal 10, @mentee.total_points
  end

  test "total_points accepts custom date range" do
    @mentee.save!

    admin_user = create_user(email: "admin@test.com")

    PointLog.create!(mentee: @mentee, points: 5, reason: "Recent", awarded_by: admin_user, log_type: "attendance", created_at: 2.days.ago)
    PointLog.create!(mentee: @mentee, points: 20, reason: "Older", awarded_by: admin_user, log_type: "attendance", created_at: 10.days.ago)

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

    # Earn 50 points
    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

    # Spend 20 points on pending redemption
    PointLog.create!(mentee: @mentee, points: -20, reason: "Gift Card", awarded_by: admin, log_type: "redemption")

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

    # Earn 50 points
    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

    # Spend 20 points on approved redemption
    PointLog.create!(mentee: @mentee, points: -20, reason: "Gift Card", awarded_by: admin, log_type: "redemption")

    assert_equal 30, @mentee.total_points
  end

  test "total_points does not deduct for denied redemptions when refunded" do
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

    # Earn 50 points
    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

    # Redemption was denied and points refunded
    PointLog.create!(mentee: @mentee, points: -20, reason: "Gift Card", awarded_by: admin, log_type: "redemption")
    PointLog.create!(mentee: @mentee, points: 20, reason: "Refund for denied redemption", awarded_by: admin, log_type: "adjustment")

    assert_equal 50, @mentee.total_points
  end

  test "total_points handles deleted redemptions with refund" do
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

    # Earn 50 points
    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

    # Spend and then refund
    PointLog.create!(mentee: @mentee, points: -20, reason: "Gift Card", awarded_by: admin, log_type: "redemption")
    PointLog.create!(mentee: @mentee, points: 20, reason: "Refund for deleted redemption", awarded_by: admin, log_type: "adjustment")

    assert_equal 50, @mentee.total_points
  end

  test "total_points handles deleted redemptions without refund" do
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

    # Earn 50 points
    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

    # Spend without refund
    PointLog.create!(mentee: @mentee, points: -20, reason: "Gift Card", awarded_by: admin, log_type: "redemption")

    assert_equal 30, @mentee.total_points
  end

  test "total_points handles multiple redemptions and adjustments" do
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

    # Earn 50 points
    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

    # Multiple redemptions
    PointLog.create!(mentee: @mentee, points: -10, reason: "Gift Card 1", awarded_by: admin, log_type: "redemption")
    PointLog.create!(mentee: @mentee, points: -10, reason: "Gift Card 2", awarded_by: admin, log_type: "redemption")
    PointLog.create!(mentee: @mentee, points: -10, reason: "Gift Card 3 - Denied", awarded_by: admin, log_type: "redemption")
    PointLog.create!(mentee: @mentee, points: 10, reason: "Refund for denied", awarded_by: admin, log_type: "adjustment")

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
    admin = create_user(email: "afford_admin@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

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

    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")
    PointLog.create!(mentee: @mentee, points: -30, reason: "Gift Card", awarded_by: admin, log_type: "redemption")

    assert_not @mentee.can_afford?(25)
  end

  test "can_afford? returns true when mentee has exactly enough points" do
    @mentee.save!
    admin = create_user(email: "afford_admin3@example.com")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    PointLog.create!(mentee: @mentee, points: 50, reason: "Event", awarded_by: admin, log_type: "attendance")

    assert @mentee.can_afford?(50)
  end
end
