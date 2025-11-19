# frozen_string_literal: true

module Types
  class OlympicSeasonQueryInput < Types::BaseInputObject
    argument :name, String, required: false
  end
end
