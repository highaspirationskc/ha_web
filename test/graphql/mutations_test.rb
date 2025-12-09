# frozen_string_literal: true

require "test_helper"

class GraphQL::MutationsTest < ActiveSupport::TestCase
  def setup
    # Create authenticated user
    @user = create_user(email: "test@example.com")
    @token = AuthService.generate_token(@user)

    # Create test data
    @team = Team.create!(name: "Test Team", color: :blue)
    @event_type = EventType.create!(name: "Test Event Type", point_value: 10, category: :org)
  end

  # Team mutations
  test "createTeam mutation creates a new team" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
            name
            color
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: { name: "New Team", color: "red" }
    }, context: { current_user: @user })

    team_data = result.dig("data", "createTeam", "team")
    errors = result.dig("data", "createTeam", "errors")

    assert_not_nil team_data
    assert_equal "New Team", team_data["name"]
    assert_equal "red", team_data["color"]
    assert_empty errors
  end

  test "updateTeam mutation updates existing team" do
    mutation = <<~GQL
      mutation($input: UpdateTeamInput!) {
        updateTeam(input: $input) {
          team {
            id
            name
            color
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: { id: @team.id, name: "Updated Team" }
    }, context: { current_user: @user })

    team_data = result.dig("data", "updateTeam", "team")
    errors = result.dig("data", "updateTeam", "errors")

    assert_not_nil team_data
    assert_equal "Updated Team", team_data["name"]
    assert_empty errors
  end

  test "deleteTeam mutation deletes a team" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteTeam(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: @team.id
    }, context: { current_user: @user })

    success = result.dig("data", "deleteTeam", "success")
    errors = result.dig("data", "deleteTeam", "errors")

    assert success
    assert_empty errors
    assert_nil Team.find_by(id: @team.id)
  end

  # Event mutations
  test "createEvent mutation creates a new event" do
    mutation = <<~GQL
      mutation($input: CreateEventInput!) {
        createEvent(input: $input) {
          event {
            id
            name
            description
            eventDate
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "New Event",
        description: "Test event",
        eventDate: "2025-12-15",
        location: "Test Location",
        eventTypeId: @event_type.id
      }
    }, context: { current_user: @user })

    event_data = result.dig("data", "createEvent", "event")
    errors = result.dig("data", "createEvent", "errors")

    assert_not_nil event_data
    assert_equal "New Event", event_data["name"]
    assert_empty errors
  end

  # Event Log mutations
  test "createEventLog mutation creates a log entry with arrived type" do
    mentee_user = create_mentee_user(email: "mentee@example.com")
    event = Event.create!(
      name: "Test Event",
      event_date: Date.current,
      event_type: @event_type,
      created_by: @user
    )

    mutation = <<~GQL
      mutation($input: CreateEventLogInput!) {
        createEventLog(input: $input) {
          eventLog {
            id
            logType
            loggedAt
            pointsAwarded
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        eventId: event.id,
        userId: mentee_user.id,
        logType: "arrived"
      }
    }, context: { current_user: @user })

    log_data = result.dig("data", "createEventLog", "eventLog")
    errors = result.dig("data", "createEventLog", "errors")

    assert_not_nil log_data
    assert_equal "arrived", log_data["logType"]
    assert_equal @event_type.point_value, log_data["pointsAwarded"]
    assert_empty errors
  end

  # Authentication tests
  test "mutations require authentication" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
            name
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: { name: "New Team", color: "red" }
    }, context: {})

    assert_nil result.dig("data", "createTeam")
    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
