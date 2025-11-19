# frozen_string_literal: true

module Types
  class LogoutInput < Types::BaseInputObject
    description "Input for user logout (empty)"

    has_no_arguments(true)
  end
end
