# frozen_string_literal: true

module Types
  class CreateUserRelationshipInput < Types::BaseInputObject
    description "Input for creating a user relationship"

    argument :user_id, ID, required: true
    argument :related_user_id, ID, required: true
    argument :relationship_type, String, required: true
  end
end
