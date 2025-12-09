# frozen_string_literal: true

module Types
  class CreateTeamInput < Types::BaseInputObject
    argument :name, String, required: true
    argument :color, String, required: true
    argument :icon_id, ID, required: false
  end
end
