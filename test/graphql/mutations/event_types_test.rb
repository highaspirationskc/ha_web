# frozen_string_literal: true

require "test_helper"

class EventTypesMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "admin@example.com")

    @event_type = EventType.create!(name: "Existing Type", point_value: 5, category: :org)
  end

  # CreateEventType tests

  test "authenticated user can create event type" do
    mutation = <<~GQL
      mutation($input: CreateEventTypeInput!) {
        createEventType(input: $input) {
          eventType {
            id
            name
            pointValue
            category
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "New Event Type",
        pointValue: 10,
        category: "user"
      }
    }, context: { current_user: @admin })

    event_type = result.dig("data", "createEventType", "eventType")
    errors = result.dig("data", "createEventType", "errors")

    assert_not_nil event_type
    assert_equal "New Event Type", event_type["name"]
    assert_equal 10, event_type["pointValue"]
    assert_equal "user", event_type["category"]
    assert_empty errors
  end

  test "create event type requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateEventTypeInput!) {
        createEventType(input: $input) {
          eventType {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "New Type",
        pointValue: 5,
        category: "org"
      }
    }, context: {})

    assert_nil result.dig("data", "createEventType")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  # UpdateEventType tests

  test "authenticated user can update event type" do
    mutation = <<~GQL
      mutation($input: UpdateEventTypeInput!) {
        updateEventType(input: $input) {
          eventType {
            id
            name
            pointValue
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @event_type.id.to_s,
        name: "Updated Type Name",
        pointValue: 15
      }
    }, context: { current_user: @admin })

    event_type = result.dig("data", "updateEventType", "eventType")
    errors = result.dig("data", "updateEventType", "errors")

    assert_not_nil event_type
    assert_equal "Updated Type Name", event_type["name"]
    assert_equal 15, event_type["pointValue"]
    assert_empty errors
  end

  test "update event type returns error for non-existent type" do
    mutation = <<~GQL
      mutation($input: UpdateEventTypeInput!) {
        updateEventType(input: $input) {
          eventType {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: "99999",
        name: "Ghost Type"
      }
    }, context: { current_user: @admin })

    event_type = result.dig("data", "updateEventType", "eventType")
    errors = result.dig("data", "updateEventType", "errors")

    assert_nil event_type
    assert_includes errors, "Event type not found"
  end

  # DeleteEventType tests

  test "authenticated user can delete event type" do
    type_to_delete = EventType.create!(name: "Delete Me", point_value: 1, category: :org)

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteEventType(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: type_to_delete.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteEventType", "success")
    errors = result.dig("data", "deleteEventType", "errors")

    assert success
    assert_empty errors
    assert_nil EventType.find_by(id: type_to_delete.id)
  end

  test "delete event type returns error for non-existent type" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteEventType(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: "99999"
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteEventType", "success")
    errors = result.dig("data", "deleteEventType", "errors")

    assert_not success
    assert_includes errors, "Event type not found"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
