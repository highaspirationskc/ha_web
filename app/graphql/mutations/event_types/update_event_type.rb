# frozen_string_literal: true

module Mutations
  module EventTypes
    class UpdateEventType < AuthenticatedMutation
      graphql_name "UpdateEventType"
      description "Update an existing event type"

      argument :input, Types::UpdateEventTypeInput, required: true

      field :event_type, Types::EventTypeType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event_type = ::EventType.find_by(id: input[:id])

        return { event_type: nil, errors: ["Event type not found"] } unless event_type

        if event_type.update(input.to_h.except(:id))
          { event_type: event_type, errors: [] }
        else
          { event_type: nil, errors: event_type.errors.full_messages }
        end
      end
    end
  end
end
