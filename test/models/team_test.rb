require "test_helper"

class TeamTest < ActiveSupport::TestCase
  def setup
    @team = Team.new(name: "Test Team", color: "blue")
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
    duplicate = Team.new(name: "Test Team", color: "red")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  # Color enum with string values
  test "has color enum" do
    assert_respond_to @team, :color
    assert_respond_to @team, :blue?
    assert_respond_to @team, :green?
    assert_respond_to @team, :yellow?
    assert_respond_to @team, :red?
  end

  test "can set color to blue" do
    @team.color = "blue"
    @team.save!
    assert @team.blue?
  end

  test "can set color to green" do
    @team.color = "green"
    @team.save!
    assert @team.green?
  end

  test "can set color to yellow" do
    @team.color = "yellow"
    @team.save!
    assert @team.yellow?
  end

  test "can set color to red" do
    @team.color = "red"
    @team.save!
    assert @team.red?
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
    other_team = Team.create!(name: "Other Team", color: "red")

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
end
