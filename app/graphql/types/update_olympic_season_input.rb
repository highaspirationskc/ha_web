# frozen_string_literal: true

module Types
  class UpdateOlympicSeasonInput < Types::BaseInputObject
    description "Input for updating an olympic season"

    argument :id, ID, required: true
    argument :name, String, required: false
    argument :start_month, Integer, required: false
    argument :start_day, Integer, required: false
    argument :end_month, Integer, required: false
    argument :end_day, Integer, required: false
  end
end
