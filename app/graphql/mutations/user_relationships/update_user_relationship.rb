# frozen_string_literal: true

module Mutations
  module UserRelationships
    class UpdateUserRelationship < AuthenticatedMutation
      description "Update an existing user relationship"

      argument :input, Types::UpdateUserRelationshipInput, required: true

      field :user_relationship, Types::UserRelationshipType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        user_relationship = UserRelationship.find_by(id: input[:id])

        return { user_relationship: nil, errors: ["User relationship not found"] } unless user_relationship

        unless can_update_relationship?(user_relationship)
          return { user_relationship: nil, errors: ["You don't have permission to update this relationship"] }
        end

        if user_relationship.update(input.to_h.except(:id))
          { user_relationship: user_relationship, errors: [] }
        else
          { user_relationship: nil, errors: user_relationship.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.admin? || current_user.staff?
      end

      def can_update_relationship?(relationship)
        # Only superusers can update relationships
        superuser?
      end
    end
  end
end
