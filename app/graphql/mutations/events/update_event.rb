# frozen_string_literal: true

module Mutations
  module Events
    class UpdateEvent < AuthenticatedMutation
      description "Update an existing event"

      argument :input, Types::UpdateEventInput, required: true

      field :event, Types::EventType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event = Event.find_by(id: input[:id])

        return { event: nil, errors: ["Event not found"] } unless event

        if event.update(input.to_h.except(:id))
          { event: event, errors: [] }
        else
          { event: nil, errors: event.errors.full_messages }
        end
      end
    end
  end
end
