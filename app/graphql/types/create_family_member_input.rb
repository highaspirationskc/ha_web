# frozen_string_literal: true

module Types
  class CreateFamilyMemberInput < Types::BaseInputObject
    description "Input for creating a family member relationship"

    argument :guardian_id, ID, required: true
    argument :mentee_id, ID, required: true
    argument :relationship_type, String, required: true
  end
end
