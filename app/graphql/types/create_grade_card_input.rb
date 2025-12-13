# frozen_string_literal: true

module Types
  class CreateGradeCardInput < Types::BaseInputObject
    description "Input for creating a grade card"

    argument :mentee_id, ID, required: true
    argument :medium_id, ID, required: true
    argument :description, String, required: false
  end
end
