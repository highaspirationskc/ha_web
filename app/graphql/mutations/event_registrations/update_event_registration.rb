# frozen_string_literal: true

module Mutations
  module EventRegistrations
    class UpdateEventRegistration < AuthenticatedMutation
      description "Update an existing event registration"

      argument :input, Types::UpdateEventRegistrationInput, required: true

      field :event_registration, Types::EventRegistrationType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event_registration = EventRegistration.find_by(id: input[:id])

        return { event_registration: nil, errors: ["Event registration not found"] } unless event_registration

        if event_registration.update(input.to_h.except(:id))
          { event_registration: event_registration, errors: [] }
        else
          { event_registration: nil, errors: event_registration.errors.full_messages }
        end
      end
    end
  end
end
