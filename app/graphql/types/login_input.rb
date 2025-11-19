# frozen_string_literal: true

module Types
  class LoginInput < Types::BaseInputObject
    description "Input for user login"

    argument :email, String, required: true
    argument :password, String, required: true
    argument :device_name, String, required: false
  end
end
