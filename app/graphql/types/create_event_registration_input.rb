# frozen_string_literal: true

module Types
  class CreateEventRegistrationInput < Types::BaseInputObject
    description "Input for creating an event registration"

    argument :event_id, ID, required: true
    argument :user_id, ID, required: true
    argument :registration_date, GraphQL::Types::ISO8601Date, required: false
  end
end
