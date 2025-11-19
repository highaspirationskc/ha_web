# frozen_string_literal: true

module Types
  class CreateEventInput < Types::BaseInputObject
    description "Input for creating an event"

    argument :name, String, required: true
    argument :event_date, GraphQL::Types::ISO8601Date, required: true
    argument :event_type_id, ID, required: true
    argument :description, String, required: false
    argument :location, String, required: false
  end
end
