# frozen_string_literal: true

module Types
  class CreateEventTypeInput < Types::BaseInputObject
    description "Input for creating an event type"

    argument :name, String, required: true
    argument :point_value, Integer, required: true
    argument :category, String, required: true
  end
end
