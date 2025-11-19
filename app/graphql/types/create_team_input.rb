# frozen_string_literal: true

module Types
  class CreateTeamInput < Types::BaseInputObject
    argument :name, String, required: true
    argument :color, String, required: true
    argument :icon_url, String, required: false
  end
end
