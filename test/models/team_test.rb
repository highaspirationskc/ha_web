require "test_helper"

class TeamTest < ActiveSupport::TestCase
  def setup
    @team = Team.new(name: "Test Team", color: "#3B82F6")
  end

  # Validations
  test "is valid with name and color" do
    assert @team.valid?
  end

  test "is invalid without a name" do
    @team.name = nil
    assert_not @team.valid?
    assert_includes @team.errors[:name], "can't be blank"
  end

  test "is invalid without a color" do
    @team.color = nil
    assert_not @team.valid?
    assert_includes @team.errors[:color], "can't be blank"
  end

  test "name must be unique" do
    @team.save!
    duplicate = Team.new(name: "Test Team", color: "#E11D48")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  # Hex color validation
  test "accepts valid hex color" do
    @team.color = "#FF5733"
    assert @team.valid?
  end

  test "accepts lowercase hex color" do
    @team.color = "#ff5733"
    assert @team.valid?
  end

  test "rejects color without hash" do
    @team.color = "3B82F6"
    assert_not @team.valid?
    assert_includes @team.errors[:color], "must be a valid hex color"
  end

  test "rejects color with wrong length" do
    @team.color = "#FFF"
    assert_not @team.valid?
    assert_includes @team.errors[:color], "must be a valid hex color"
  end

  test "rejects non-hex characters" do
    @team.color = "#ZZZZZZ"
    assert_not @team.valid?
    assert_includes @team.errors[:color], "must be a valid hex color"
  end

  test "rejects plain color names" do
    @team.color = "blue"
    assert_not @team.valid?
    assert_includes @team.errors[:color], "must be a valid hex color"
  end

  # COLORS constant
  test "has COLORS constant with 25 colors" do
    assert_equal 25, Team::COLORS.length
    assert Team::COLORS.all? { |c| c.match?(/\A#[0-9A-Fa-f]{6}\z/) }
  end

  # color_hex helper
  test "color_hex returns the color value" do
    assert_equal "#3B82F6", @team.color_hex
  end

  # Multiple teams can share the same color
  test "allows duplicate colors" do
    @team.save!
    second_team = Team.new(name: "Second Team", color: "#3B82F6")
    assert second_team.valid?
  end

  # Associations - now with Mentee instead of User
  test "has many mentees" do
    assert_respond_to @team, :mentees
  end

  test "can have multiple mentees" do
    @team.save!

    user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    user2 = User.create!(email: "mentee2@example.com", password: "Password123!")

    mentee1 = Mentee.create!(user: user1, team: @team)
    mentee2 = Mentee.create!(user: user2, team: @team)

    assert_includes @team.mentees, mentee1
    assert_includes @team.mentees, mentee2
    assert_equal 2, @team.mentees.count
  end

  test "nullifies mentee team_id when team is destroyed" do
    @team.save!

    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    @team.destroy

    mentee.reload
    assert_nil mentee.team_id
  end

  # Should not have direct user association anymore
  test "does not have direct users association" do
    assert_not_respond_to @team, :users
    assert_not_respond_to @team, :members
  end

  # Icon cascade delete tests
  test "should destroy icon medium when team is destroyed" do
    admin = create_user
    icon = Medium.create!(
      uploaded_by: admin,
      cloudflare_id: "icon_team_test_#{SecureRandom.hex(8)}",
      filename: "icon.png",
      media_type: "image",
      category: "icon"
    )
    @team.icon = icon
    @team.save!

    CloudflareImagesService.stubs(:delete).returns(true)
    assert_difference "Medium.count", -1 do
      @team.destroy
    end
  end

  test "should not destroy general medium when team is destroyed" do
    admin = create_user
    general_medium = Medium.create!(
      uploaded_by: admin,
      cloudflare_id: "general_team_test_#{SecureRandom.hex(8)}",
      filename: "image.jpg",
      media_type: "image",
      category: "general"
    )
    @team.icon = general_medium
    @team.save!

    assert_no_difference "Medium.count" do
      @team.destroy
    end
  end

  # Community Service Hours
  test "total_community_service_hours returns 0 when no mentees have records" do
    @team.save!
    assert_equal 0, @team.total_community_service_hours
  end

  test "total_community_service_hours returns 0 when no current season exists" do
    @team.save!
    OlympicSeason.delete_all

    assert_equal 0, @team.total_community_service_hours
  end

  test "total_community_service_hours sums approved hours from all team mentees" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    user2 = User.create!(email: "mentee2@example.com", password: "Password123!")
    mentee1 = Mentee.create!(user: user1, team: @team)
    mentee2 = Mentee.create!(user: user2, team: @team)

    CommunityServiceRecord.create!(mentee: mentee1, event: "Event 1", event_date: Date.current, hours: 2.5)
    CommunityServiceRecord.create!(mentee: mentee2, event: "Event 2", event_date: Date.current, hours: 1.5)

    assert_equal 4.0, @team.total_community_service_hours
  end

  test "total_community_service_hours excludes denied records" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    CommunityServiceRecord.create!(mentee: mentee, event: "Approved", event_date: Date.current, hours: 3.0, approved: true)
    CommunityServiceRecord.create!(mentee: mentee, event: "Denied", event_date: Date.current, hours: 10.0, approved: false)

    assert_equal 3.0, @team.total_community_service_hours
  end

  test "total_community_service_hours excludes records from other teams" do
    @team.save!
    other_team = Team.create!(name: "Other Team", color: "#E11D48")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    user2 = User.create!(email: "mentee2@example.com", password: "Password123!")
    mentee1 = Mentee.create!(user: user1, team: @team)
    mentee2 = Mentee.create!(user: user2, team: other_team)

    CommunityServiceRecord.create!(mentee: mentee1, event: "My Team", event_date: Date.current, hours: 5.0)
    CommunityServiceRecord.create!(mentee: mentee2, event: "Other Team", event_date: Date.current, hours: 100.0)

    assert_equal 5.0, @team.total_community_service_hours
  end

  test "total_community_service_hours accepts custom date range" do
    @team.save!

    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    CommunityServiceRecord.create!(mentee: mentee, event: "Recent", event_date: 2.days.ago.to_date, hours: 2.0)
    CommunityServiceRecord.create!(mentee: mentee, event: "Older", event_date: 10.days.ago.to_date, hours: 8.0)

    week_range = 1.week.ago.to_date..Date.current
    assert_equal 2.0, @team.total_community_service_hours(week_range)
  end

  # Team Points Tests
  test "total_points returns 0 when team has no mentees" do
    @team.save!
    assert_equal 0, @team.total_points
  end

  test "total_points returns 0 when no current season exists" do
    @team.save!
    OlympicSeason.delete_all

    assert_equal 0, @team.total_points
  end

  test "total_points sums individual mentee totals for all team members" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    admin = create_user(email: "admin@test.com")
    user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    user2 = User.create!(email: "mentee2@example.com", password: "Password123!")
    mentee1 = Mentee.create!(user: user1, team: @team)
    mentee2 = Mentee.create!(user: user2, team: @team)

    # Give each mentee 50 points
    PointLog.create!(mentee: mentee1, points: 50, reason: "Attendance", awarded_by: admin, log_type: "attendance")
    PointLog.create!(mentee: mentee2, points: 50, reason: "Attendance", awarded_by: admin, log_type: "attendance")

    assert_equal 100, @team.total_points
  end

  test "total_points deducts approved redemptions from all mentees" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    admin = create_user(email: "admin@test.com")
    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    # Give mentee 100 points
    PointLog.create!(mentee: mentee, points: 100, reason: "Attendance", awarded_by: admin, log_type: "attendance")

    # Create approved redemption for 30 points
    incentive = Incentive.create!(name: "Test", point_cost: 30, incentive_type: "individual", created_by: admin)
    Redemption.create!(mentee: mentee, incentive: incentive, points_spent: 30, status: "approved")

    assert_equal 70, @team.total_points
  end

  test "total_points does not deduct denied redemptions (pointable scope)" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    admin = create_user(email: "admin@test.com")
    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    # Give mentee 100 points
    PointLog.create!(mentee: mentee, points: 100, reason: "Attendance", awarded_by: admin, log_type: "attendance")

    # Create denied redemption - points should be restored
    incentive = Incentive.create!(name: "Test", point_cost: 30, incentive_type: "individual", created_by: admin)
    Redemption.create!(mentee: mentee, incentive: incentive, points_spent: 30, status: "denied")

    assert_equal 100, @team.total_points
  end

  test "total_points does not deduct deleted redemptions (pointable scope)" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    admin = create_user(email: "admin@test.com")
    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    # Give mentee 100 points
    PointLog.create!(mentee: mentee, points: 100, reason: "Attendance", awarded_by: admin, log_type: "attendance")

    # Create deleted redemption (with refund) - points should be restored
    incentive = Incentive.create!(name: "Test", point_cost: 30, incentive_type: "individual", created_by: admin)
    Redemption.create!(mentee: mentee, incentive: incentive, points_spent: 30, status: "deleted")

    assert_equal 100, @team.total_points
  end

  test "total_points still deducts deleted_no_refund redemptions" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    admin = create_user(email: "admin@test.com")
    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    # Give mentee 100 points
    PointLog.create!(mentee: mentee, points: 100, reason: "Attendance", awarded_by: admin, log_type: "attendance")

    # Create deleted_no_refund redemption - points should still be deducted
    incentive = Incentive.create!(name: "Test", point_cost: 30, incentive_type: "individual", created_by: admin)
    Redemption.create!(mentee: mentee, incentive: incentive, points_spent: 30, status: "deleted_no_refund")

    assert_equal 70, @team.total_points
  end

  test "total_points handles mentees with mixed redemption statuses" do
    @team.save!

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    admin = create_user(email: "admin@test.com")
    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    # Give mentee 100 points
    PointLog.create!(mentee: mentee, points: 100, reason: "Attendance", awarded_by: admin, log_type: "attendance")

    # Multiple redemptions with different statuses
    incentive1 = Incentive.create!(name: "Approved Item", point_cost: 10, incentive_type: "individual", created_by: admin)
    incentive2 = Incentive.create!(name: "Denied Item", point_cost: 15, incentive_type: "individual", created_by: admin)
    incentive3 = Incentive.create!(name: "Deleted Item", point_cost: 20, incentive_type: "individual", created_by: admin)
    incentive4 = Incentive.create!(name: "No Refund Item", point_cost: 5, incentive_type: "individual", created_by: admin)

    Redemption.create!(mentee: mentee, incentive: incentive1, points_spent: 10, status: "approved")
    Redemption.create!(mentee: mentee, incentive: incentive2, points_spent: 15, status: "denied")
    Redemption.create!(mentee: mentee, incentive: incentive3, points_spent: 20, status: "deleted")
    Redemption.create!(mentee: mentee, incentive: incentive4, points_spent: 5, status: "deleted_no_refund")

    # Only approved (10) and deleted_no_refund (5) should deduct = 15 total deducted
    # 100 - 15 = 85
    assert_equal 85, @team.total_points
  end

  test "total_points accepts custom date range" do
    @team.save!

    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    admin = create_user(email: "admin@test.com")

    # Point logs in different time periods
    PointLog.create!(mentee: mentee, points: 50, reason: "Recent", awarded_by: admin, log_type: "attendance", created_at: 2.days.ago)
    PointLog.create!(mentee: mentee, points: 30, reason: "Old", awarded_by: admin, log_type: "attendance", created_at: 10.days.ago)

    week_range = 1.week.ago.to_date.beginning_of_day..Date.current.end_of_day
    assert_equal 50, @team.total_points(week_range)
  end

  test "total_points excludes points from mentees on other teams" do
    @team.save!
    other_team = Team.create!(name: "Other Team", color: "#E11D48")

    today = Date.current
    OlympicSeason.create!(
      name: "Test Season",
      start_month: (today - 1.month).month,
      start_day: (today - 1.month).day,
      end_month: (today + 1.month).month,
      end_day: (today + 1.month).day
    )

    admin = create_user(email: "admin@test.com")
    user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    user2 = User.create!(email: "mentee2@example.com", password: "Password123!")
    mentee1 = Mentee.create!(user: user1, team: @team)
    mentee2 = Mentee.create!(user: user2, team: other_team)

    PointLog.create!(mentee: mentee1, points: 50, reason: "My Team", awarded_by: admin, log_type: "attendance")
    PointLog.create!(mentee: mentee2, points: 100, reason: "Other Team", awarded_by: admin, log_type: "attendance")

    assert_equal 50, @team.total_points
  end
end
