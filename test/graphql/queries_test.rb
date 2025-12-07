# frozen_string_literal: true

require "test_helper"

class GraphQL::QueriesTest < ActiveSupport::TestCase
  def setup
    # Create authenticated user
    @user = User.create!(email: "test@example.com", password: "Password123!", role: :admin)
    @user.activate!
    @token = AuthService.generate_token(@user)

    # Load seed data
    Rails.application.load_seed
  end

  def teardown
    # Clean up after tests
    EventLog.destroy_all
    Event.destroy_all
    EventType.destroy_all
    OlympicSeason.destroy_all
    FamilyMember.destroy_all
    User.destroy_all
    Team.destroy_all
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
    assert_equal 4, teams.length
    assert_includes teams.map { |t| t["name"] }, "Blue Team"
  end

  test "team query returns specific team" do
    team = Team.first

    query = <<~GQL
      query($id: ID!) {
        team(id: $id) {
          id
          name
          color
        }
      }
    GQL

    result = execute_graphql(query, variables: { id: team.id }, context: { current_user: @user })
    team_data = result.dig("data", "team")

    assert_not_nil team_data
    assert_equal team.name, team_data["name"]
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
    # All events should be on or after June 1, 2025
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
    assert_equal 5, event_types.length
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
    # Should return whatever the current season is based on today's date
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
          role
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
          role
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
          user {
            email
          }
          relatedUser {
            email
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
