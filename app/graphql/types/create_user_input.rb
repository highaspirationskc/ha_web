# frozen_string_literal: true

module Types
  class CreateUserInput < Types::BaseInputObject
    description "Input for creating a user"

    argument :email, String, required: true
    argument :password, String, required: true
    argument :first_name, String, required: false
    argument :last_name, String, required: false
    argument :role, String, required: false
    argument :team_id, ID, required: false
    argument :active, Boolean, required: false
  end
end
