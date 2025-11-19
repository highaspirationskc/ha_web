# frozen_string_literal: true

module Types
  class CreateEventLogInput < Types::BaseInputObject
    description "Input for creating an event log"

    argument :event_id, ID, required: true
    argument :user_id, ID, required: true
    argument :participated_at, GraphQL::Types::ISO8601Date, required: true
    argument :points_awarded, Integer, required: true
  end
end
