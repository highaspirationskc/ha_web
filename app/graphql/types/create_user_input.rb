# frozen_string_literal: true

module Types
  class CreateUserInput < Types::BaseInputObject
    description "Input for creating a user"

    argument :email, String, required: true
    argument :password, String, required: false, description: "Password (optional - random password generated if blank)"
    argument :first_name, String, required: false
    argument :last_name, String, required: false

    # Role selection (required)
    argument :role, String, required: true, description: "The role for this user (staff, mentor, mentee, guardian, volunteer)"

    # Staff-specific fields
    argument :permission_level, String, required: false,
      description: "Permission level for staff users: standard or admin (defaults to standard)"

    # Mentee-specific fields
    argument :team_id, ID, required: false, description: "Team assignment for mentee users"
    argument :mentor_id, ID, required: false, description: "Mentor assignment for mentee users"
  end
end
