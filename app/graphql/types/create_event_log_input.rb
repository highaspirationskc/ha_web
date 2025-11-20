# frozen_string_literal: true

module Types
  class CreateEventLogInput < Types::BaseInputObject
    description "Input for creating an event log"

    argument :event_id, ID, required: true
    argument :user_id, ID, required: true
    argument :log_type, String, required: true, description: "Type of log entry: 'registered' or 'arrived'"
    argument :logged_at, GraphQL::Types::ISO8601DateTime, required: false, description: "Timestamp (defaults to now)"
  end
end
