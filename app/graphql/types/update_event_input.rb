# frozen_string_literal: true

module Types
  class UpdateEventInput < Types::BaseInputObject
    description "Input for updating an event"

    argument :id, ID, required: true
    argument :name, String, required: false
    argument :event_date, GraphQL::Types::ISO8601Date, required: false
    argument :event_type_id, ID, required: false
    argument :description, String, required: false
    argument :location, String, required: false
  end
end
