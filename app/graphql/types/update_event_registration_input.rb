# frozen_string_literal: true

module Types
  class UpdateEventRegistrationInput < Types::BaseInputObject
    description "Input for updating an event registration"

    argument :id, ID, required: true
    argument :event_id, ID, required: false
    argument :user_id, ID, required: false
    argument :registration_date, GraphQL::Types::ISO8601Date, required: false
  end
end
