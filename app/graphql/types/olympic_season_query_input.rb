# frozen_string_literal: true

module Types
  class OlympicSeasonQueryInput < Types::BaseInputObject
    argument :name, String, required: false
    argument :year, Integer, required: false, description: "Year to filter events (defaults to current year)"
  end
end
