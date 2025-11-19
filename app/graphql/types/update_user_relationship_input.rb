# frozen_string_literal: true

module Types
  class UpdateUserRelationshipInput < Types::BaseInputObject
    description "Input for updating a user relationship"

    argument :id, ID, required: true
    argument :user_id, ID, required: false
    argument :related_user_id, ID, required: false
    argument :relationship_type, String, required: false
  end
end
