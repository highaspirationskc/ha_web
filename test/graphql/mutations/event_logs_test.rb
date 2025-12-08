# frozen_string_literal: true

require "test_helper"

class EventLogsMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = create_admin_user(email: "admin@example.com")
    @mentee = create_mentee_user(email: "mentee@example.com")

    @event_type = EventType.create!(name: "Practice", point_value: 5, category: :org)
    @event = Event.create!(
      name: "Weekly Practice",
      event_date: Date.current + 7.days,
      event_type: @event_type,
      created_by: @admin
    )

    @event_log = EventLog.create!(
      event: @event,
      user: @mentee,
      log_type: :registered,
      logged_at: Time.current
    )
  end

  # CreateEventLog tests

  test "authenticated user can create event log" do
    another_mentee = create_mentee_user(email: "mentee2@example.com")

    mutation = <<~GQL
      mutation($input: CreateEventLogInput!) {
        createEventLog(input: $input) {
          eventLog {
            id
            logType
            pointsAwarded
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        eventId: @event.id.to_s,
        userId: another_mentee.id.to_s,
        logType: "arrived"
      }
    }, context: { current_user: @admin })

    event_log = result.dig("data", "createEventLog", "eventLog")
    errors = result.dig("data", "createEventLog", "errors")

    assert_not_nil event_log
    assert_equal "arrived", event_log["logType"]
    assert_equal 5, event_log["pointsAwarded"]
    assert_empty errors
  end

  test "create event log with registered type awards zero points" do
    another_mentee = create_mentee_user(email: "mentee3@example.com")

    mutation = <<~GQL
      mutation($input: CreateEventLogInput!) {
        createEventLog(input: $input) {
          eventLog {
            id
            logType
            pointsAwarded
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        eventId: @event.id.to_s,
        userId: another_mentee.id.to_s,
        logType: "registered"
      }
    }, context: { current_user: @admin })

    event_log = result.dig("data", "createEventLog", "eventLog")
    errors = result.dig("data", "createEventLog", "errors")

    assert_not_nil event_log
    assert_equal "registered", event_log["logType"]
    assert_equal 0, event_log["pointsAwarded"]
    assert_empty errors
  end

  test "create event log requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateEventLogInput!) {
        createEventLog(input: $input) {
          eventLog {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        eventId: @event.id.to_s,
        userId: @mentee.id.to_s,
        logType: "arrived"
      }
    }, context: {})

    assert_nil result.dig("data", "createEventLog")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  # UpdateEventLog tests

  test "authenticated user can update event log" do
    mutation = <<~GQL
      mutation($input: UpdateEventLogInput!) {
        updateEventLog(input: $input) {
          eventLog {
            id
            logType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @event_log.id.to_s,
        logType: "arrived"
      }
    }, context: { current_user: @admin })

    event_log = result.dig("data", "updateEventLog", "eventLog")
    errors = result.dig("data", "updateEventLog", "errors")

    assert_not_nil event_log
    assert_equal "arrived", event_log["logType"]
    assert_empty errors
  end

  test "update event log returns error for non-existent log" do
    mutation = <<~GQL
      mutation($input: UpdateEventLogInput!) {
        updateEventLog(input: $input) {
          eventLog {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: "99999",
        logType: "arrived"
      }
    }, context: { current_user: @admin })

    event_log = result.dig("data", "updateEventLog", "eventLog")
    errors = result.dig("data", "updateEventLog", "errors")

    assert_nil event_log
    assert_includes errors, "Event log not found"
  end

  # DeleteEventLog tests

  test "authenticated user can delete event log" do
    log_to_delete = EventLog.create!(
      event: @event,
      user: @mentee,
      log_type: :arrived,
      logged_at: Time.current
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteEventLog(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: log_to_delete.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteEventLog", "success")
    errors = result.dig("data", "deleteEventLog", "errors")

    assert success
    assert_empty errors
    assert_nil EventLog.find_by(id: log_to_delete.id)
  end

  test "delete event log returns error for non-existent log" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteEventLog(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: "99999"
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteEventLog", "success")
    errors = result.dig("data", "deleteEventLog", "errors")

    assert_not success
    assert_includes errors, "Event log not found"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
