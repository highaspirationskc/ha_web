# frozen_string_literal: true

require "test_helper"

class GraphQL::QueriesTest < ActiveSupport::TestCase
  def setup
    @user = create_user(email: "gql_test@example.com")
    @token = AuthService.generate_token(@user)

    @team = Team.create!(name: "Blue Team", color: "#3B82F6")
    Team.create!(name: "Red Team", color: "#E11D48")

    @winter = OlympicSeason.create!(name: "Winter", start_month: 12, start_day: 1, end_month: 2, end_day: 28)
    @spring = OlympicSeason.create!(name: "Spring", start_month: 3, start_day: 1, end_month: 5, end_day: 31)
    @summer = OlympicSeason.create!(name: "Summer", start_month: 6, start_day: 1, end_month: 8, end_day: 31)
    @fall = OlympicSeason.create!(name: "Fall", start_month: 9, start_day: 1, end_month: 11, end_day: 30)

    @workshop = EventType.create!(name: "Workshop", point_value: 1, category: :org)
    @mentoring = EventType.create!(name: "Mentoring Session", point_value: 1, category: :user)

    @past_event = Event.create!(
      name: "Past Workshop",
      event_date: 2.weeks.ago,
      event_type: @workshop,
      created_by: @user
    )
    @future_event = Event.create!(
      name: "Summer Workshop",
      event_date: Date.new(2026, 7, 4),
      event_type: @mentoring,
      created_by: @user
    )

    mentee_user = User.create!(email: "gql_mentee@example.com", password: "Password123!")
    mentee_user.activate!
    @mentee = Mentee.create!(user: mentee_user, team: @team)

    EventLog.create!(event: @past_event, user: mentee_user, log_type: :arrived, logged_at: 2.weeks.ago)

    guardian_user = User.create!(email: "gql_guardian@example.com", password: "Password123!")
    guardian_user.activate!
    guardian = Guardian.create!(user: guardian_user)
    FamilyMember.create!(guardian: guardian, mentee: @mentee, relationship_type: :parent)
  end

  # Teams queries
  test "teams query returns all teams" do
    query = <<~GQL
      query {
        teams {
          id
          name
          color
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    teams = result.dig("data", "teams")

    assert_not_nil teams
    assert_equal 2, teams.length
    assert_includes teams.map { |t| t["name"] }, "Blue Team"
  end

  test "team query returns specific team" do
    query = <<~GQL
      query($id: ID!) {
        team(id: $id) {
          id
          name
          color
        }
      }
    GQL

    result = execute_graphql(query, variables: { id: @team.id }, context: { current_user: @user })
    team_data = result.dig("data", "team")

    assert_not_nil team_data
    assert_equal @team.name, team_data["name"]
  end

  # Events queries
  test "events query returns all events" do
    query = <<~GQL
      query {
        events {
          id
          name
          eventDate
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    events = result.dig("data", "events")

    assert_not_nil events
    assert events.length > 0
  end

  test "events query with start_date filter" do
    query = <<~GQL
      query($input: EventsFilterInput) {
        events(input: $input) {
          id
          name
          eventDate
        }
      }
    GQL

    result = execute_graphql(
      query,
      variables: { input: { startDate: "2025-06-01" } },
      context: { current_user: @user }
    )
    events = result.dig("data", "events")

    assert_not_nil events
    events.each do |event|
      event_date = Date.parse(event["eventDate"])
      assert event_date >= Date.new(2025, 6, 1)
    end
  end

  # Event Types queries
  test "event_types query returns all event types" do
    query = <<~GQL
      query {
        eventTypes {
          id
          name
          pointValue
          category
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    event_types = result.dig("data", "eventTypes")

    assert_not_nil event_types
    assert_equal 2, event_types.length
  end

  # Olympic Seasons queries
  test "olympic_seasons query returns all seasons" do
    query = <<~GQL
      query {
        olympicSeasons {
          id
          name
          startMonth
          startDay
          endMonth
          endDay
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    seasons = result.dig("data", "olympicSeasons")

    assert_not_nil seasons
    assert_equal 4, seasons.length
    assert_includes seasons.map { |s| s["name"] }, "Winter"
  end

  test "olympic_season query returns current season when no input" do
    query = <<~GQL
      query {
        olympicSeason {
          id
          name
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    season = result.dig("data", "olympicSeason")

    assert_not_nil season
    expected_season = OlympicSeasonService.current_season
    assert_equal expected_season.name, season["name"]
  end

  test "olympic_season query returns season by name" do
    query = <<~GQL
      query($input: OlympicSeasonQueryInput) {
        olympicSeason(input: $input) {
          id
          name
        }
      }
    GQL

    result = execute_graphql(
      query,
      variables: { input: { name: "Summer" } },
      context: { current_user: @user }
    )
    season = result.dig("data", "olympicSeason")

    assert_not_nil season
    assert_equal "Summer", season["name"]
  end

  # Users queries
  test "users query returns all users" do
    query = <<~GQL
      query {
        users {
          id
          email
          staff {
            permissionLevel
          }
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    users = result.dig("data", "users")

    assert_not_nil users
    assert users.length > 0
  end

  test "current_user query returns authenticated user" do
    query = <<~GQL
      query {
        currentUser {
          id
          email
          staff {
            permissionLevel
          }
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    current_user = result.dig("data", "currentUser")

    assert_not_nil current_user
    assert_equal @user.email, current_user["email"]
  end

  # Authentication tests
  test "queries require authentication" do
    query = <<~GQL
      query {
        teams {
          id
          name
        }
      }
    GQL

    result = execute_graphql(query, context: {})

    assert_nil result.dig("data", "teams")
    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  test "event_logs query returns all logs" do
    query = <<~GQL
      query {
        eventLogs {
          id
          logType
          loggedAt
          pointsAwarded
          event {
            name
          }
          user {
            email
          }
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    logs = result.dig("data", "eventLogs")

    assert_not_nil logs
    assert logs.length > 0
  end

  test "family_members query returns all relationships" do
    query = <<~GQL
      query {
        familyMembers {
          id
          relationshipType
          guardian {
            user {
              email
            }
          }
          mentee {
            user {
              email
            }
          }
        }
      }
    GQL

    result = execute_graphql(query, context: { current_user: @user })
    relationships = result.dig("data", "familyMembers")

    assert_not_nil relationships
    assert relationships.length > 0
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
