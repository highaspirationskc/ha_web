# frozen_string_literal: true

module Mutations
  module UserRelationships
    class CreateUserRelationship < AuthenticatedMutation
      description "Create a new user relationship"

      argument :input, Types::CreateUserRelationshipInput, required: true

      field :user_relationship, Types::UserRelationshipType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        user = User.find_by(id: input[:user_id])
        related_user = User.find_by(id: input[:related_user_id])

        return { user_relationship: nil, errors: ["User not found"] } unless user
        return { user_relationship: nil, errors: ["Related user not found"] } unless related_user

        # Check permissions
        unless can_create_relationship?(user, related_user, input[:relationship_type])
          return { user_relationship: nil, errors: ["You don't have permission to create this relationship"] }
        end

        # Auto-assign mentee to mentor's team when mentor adds mentee
        if current_user.mentor? && user == current_user && related_user.mentee? && input[:relationship_type] == "mentor"
          related_user.update(team_id: current_user.team_id)
        end

        user_relationship = UserRelationship.new(input.to_h)

        if user_relationship.save
          { user_relationship: user_relationship, errors: [] }
        else
          { user_relationship: nil, errors: user_relationship.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.admin? || current_user.staff?
      end

      def can_create_relationship?(user, related_user, relationship_type)
        # Superusers can create any relationship
        return true if superuser?

        # Mentors can add mentees to their team
        if current_user.mentor? && current_user.team_id
          return user == current_user && related_user.mentee? && relationship_type == "mentor"
        end

        false
      end
    end
  end
end
