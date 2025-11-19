# frozen_string_literal: true

module Mutations
  module EventTypes
    class CreateEventType < AuthenticatedMutation
      graphql_name "CreateEventType"
      description "Create a new event type"

      argument :input, Types::CreateEventTypeInput, required: true

      field :event_type, Types::EventTypeType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event_type = ::EventType.new(input.to_h)

        if event_type.save
          { event_type: event_type, errors: [] }
        else
          { event_type: nil, errors: event_type.errors.full_messages }
        end
      end
    end
  end
end
