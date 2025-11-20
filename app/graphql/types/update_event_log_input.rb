# frozen_string_literal: true

module Types
  class UpdateEventLogInput < Types::BaseInputObject
    description "Input for updating an event log"

    argument :id, ID, required: true
    argument :event_id, ID, required: false
    argument :user_id, ID, required: false
    argument :log_type, String, required: false, description: "Type of log entry: 'registered' or 'arrived'"
    argument :logged_at, GraphQL::Types::ISO8601DateTime, required: false
  end
end
