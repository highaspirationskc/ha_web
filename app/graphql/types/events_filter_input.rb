# frozen_string_literal: true

module Types
  class EventsFilterInput < Types::BaseInputObject
    argument :start_date, GraphQL::Types::ISO8601Date, required: false
    argument :end_date, GraphQL::Types::ISO8601Date, required: false
  end
end
