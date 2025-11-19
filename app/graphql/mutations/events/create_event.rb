# frozen_string_literal: true

module Mutations
  module Events
    class CreateEvent < AuthenticatedMutation
      description "Create a new event"

      argument :input, Types::CreateEventInput, required: true

      field :event, Types::EventType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event = Event.new(input.to_h.merge(created_by: current_user))

        if event.save
          { event: event, errors: [] }
        else
          { event: nil, errors: event.errors.full_messages }
        end
      end
    end
  end
end
