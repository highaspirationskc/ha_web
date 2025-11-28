# frozen_string_literal: true

require "test_helper"

class EventsMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = User.create!(email: "admin@example.com", password: "Password123!", role: :admin)
    @admin.activate!

    @mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor)
    @mentor.activate!

    @event_type = EventType.create!(name: "Meeting", point_value: 1, category: :org)
    @event = Event.create!(
      name: "Existing Event",
      event_date: Date.current + 7.days,
      event_type: @event_type,
      created_by: @admin
    )
  end

  # CreateEvent tests

  test "authenticated user can create event" do
    mutation = <<~GQL
      mutation($input: CreateEventInput!) {
        createEvent(input: $input) {
          event {
            id
            name
            eventDate
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "New Event",
        eventDate: (Date.current + 14.days).iso8601,
        eventTypeId: @event_type.id.to_s
      }
    }, context: { current_user: @admin })

    event = result.dig("data", "createEvent", "event")
    errors = result.dig("data", "createEvent", "errors")

    assert_not_nil event
    assert_equal "New Event", event["name"]
    assert_empty errors
  end

  test "create event with optional fields" do
    mutation = <<~GQL
      mutation($input: CreateEventInput!) {
        createEvent(input: $input) {
          event {
            id
            name
            description
            location
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "Full Event",
        eventDate: (Date.current + 14.days).iso8601,
        eventTypeId: @event_type.id.to_s,
        description: "Event description",
        location: "Community Center"
      }
    }, context: { current_user: @admin })

    event = result.dig("data", "createEvent", "event")
    errors = result.dig("data", "createEvent", "errors")

    assert_not_nil event
    assert_equal "Event description", event["description"]
    assert_equal "Community Center", event["location"]
    assert_empty errors
  end

  test "create event requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateEventInput!) {
        createEvent(input: $input) {
          event {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "New Event",
        eventDate: (Date.current + 14.days).iso8601,
        eventTypeId: @event_type.id.to_s
      }
    }, context: {})

    assert_nil result.dig("data", "createEvent")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  # UpdateEvent tests

  test "authenticated user can update event" do
    mutation = <<~GQL
      mutation($input: UpdateEventInput!) {
        updateEvent(input: $input) {
          event {
            id
            name
            description
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @event.id.to_s,
        name: "Updated Event Name",
        description: "New description"
      }
    }, context: { current_user: @admin })

    event = result.dig("data", "updateEvent", "event")
    errors = result.dig("data", "updateEvent", "errors")

    assert_not_nil event
    assert_equal "Updated Event Name", event["name"]
    assert_equal "New description", event["description"]
    assert_empty errors
  end

  test "update event returns error for non-existent event" do
    mutation = <<~GQL
      mutation($input: UpdateEventInput!) {
        updateEvent(input: $input) {
          event {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: "99999",
        name: "Ghost Event"
      }
    }, context: { current_user: @admin })

    event = result.dig("data", "updateEvent", "event")
    errors = result.dig("data", "updateEvent", "errors")

    assert_nil event
    assert_includes errors, "Event not found"
  end

  # DeleteEvent tests

  test "authenticated user can delete event" do
    event_to_delete = Event.create!(
      name: "Delete Me",
      event_date: Date.current + 30.days,
      event_type: @event_type,
      created_by: @admin
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteEvent(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: event_to_delete.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteEvent", "success")
    errors = result.dig("data", "deleteEvent", "errors")

    assert success
    assert_empty errors
    assert_nil Event.find_by(id: event_to_delete.id)
  end

  test "delete event returns error for non-existent event" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteEvent(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: "99999"
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteEvent", "success")
    errors = result.dig("data", "deleteEvent", "errors")

    assert_not success
    assert_includes errors, "Event not found"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
