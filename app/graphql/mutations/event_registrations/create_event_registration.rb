# frozen_string_literal: true

module Mutations
  module EventRegistrations
    class CreateEventRegistration < AuthenticatedMutation
      description "Create a new event registration"

      argument :input, Types::CreateEventRegistrationInput, required: true

      field :event_registration, Types::EventRegistrationType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        # Default registration_date to today if not provided
        input_hash = input.to_h
        input_hash[:registration_date] ||= Date.current

        event_registration = EventRegistration.new(input_hash)

        if event_registration.save
          { event_registration: event_registration, errors: [] }
        else
          { event_registration: nil, errors: event_registration.errors.full_messages }
        end
      end
    end
  end
end
