# frozen_string_literal: true

module Types
  class RegisterInput < Types::BaseInputObject
    description "Input for user registration"

    argument :email, String, required: true
    argument :password, String, required: true
  end
end
