# frozen_string_literal: true

module Types
  class CreateOlympicSeasonInput < Types::BaseInputObject
    description "Input for creating an olympic season"

    argument :name, String, required: true
    argument :start_month, Integer, required: true
    argument :start_day, Integer, required: true
    argument :end_month, Integer, required: true
    argument :end_day, Integer, required: true
  end
end
