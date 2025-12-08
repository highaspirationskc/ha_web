# frozen_string_literal: true

module Types
  class UpdateFamilyMemberInput < Types::BaseInputObject
    description "Input for updating a family member relationship"

    argument :id, ID, required: true
    argument :guardian_id, ID, required: false
    argument :mentee_id, ID, required: false
    argument :relationship_type, String, required: false
  end
end
