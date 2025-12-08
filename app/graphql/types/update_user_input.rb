# frozen_string_literal: true

module Types
  class UpdateUserInput < Types::BaseInputObject
    description "Input for updating a user"

    argument :id, ID, required: true
    argument :email, String, required: false
    argument :password, String, required: false
    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :active, Boolean, required: false
  end
end
