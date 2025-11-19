# frozen_string_literal: true

module Mutations
  module UserRelationships
    class CreateUserRelationship < AuthenticatedMutation
      description "Create a new user relationship"

      argument :input, Types::CreateUserRelationshipInput, required: true

      field :user_relationship, Types::UserRelationshipType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        user_relationship = UserRelationship.new(input.to_h)

        if user_relationship.save
          { user_relationship: user_relationship, errors: [] }
        else
          { user_relationship: nil, errors: user_relationship.errors.full_messages }
        end
      end
    end
  end
end
