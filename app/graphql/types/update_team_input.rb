# frozen_string_literal: true

module Types
  class UpdateTeamInput < Types::BaseInputObject
    description "Input for updating a team"

    argument :id, ID, required: true
    argument :name, String, required: false
    argument :color, String, required: false
    argument :icon_id, ID, required: false
  end
end
