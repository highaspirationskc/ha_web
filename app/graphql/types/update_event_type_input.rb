# frozen_string_literal: true

module Types
  class UpdateEventTypeInput < Types::BaseInputObject
    description "Input for updating an event type"

    argument :id, ID, required: true
    argument :name, String, required: false
    argument :point_value, Integer, required: false
    argument :category, String, required: false
  end
end
