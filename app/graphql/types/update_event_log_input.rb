# frozen_string_literal: true

module Types
  class UpdateEventLogInput < Types::BaseInputObject
    description "Input for updating an event log"

    argument :id, ID, required: true
    argument :event_id, ID, required: false
    argument :user_id, ID, required: false
    argument :participated_at, GraphQL::Types::ISO8601Date, required: false
    argument :points_awarded, Integer, required: false
  end
end
