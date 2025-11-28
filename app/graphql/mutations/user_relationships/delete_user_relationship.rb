# frozen_string_literal: true

module Mutations
  module UserRelationships
    class DeleteUserRelationship < AuthenticatedMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        user_relationship = UserRelationship.find_by(id: id)

        return { success: false, errors: ["User relationship not found"] } unless user_relationship

        unless can_delete_relationship?(user_relationship)
          return { success: false, errors: ["You don't have permission to delete this relationship"] }
        end

        if user_relationship.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: user_relationship.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.admin? || current_user.staff?
      end

      def can_delete_relationship?(relationship)
        # Superusers can delete any relationship
        return true if superuser?

        # Mentors can remove mentees from their team (relationships they own)
        if current_user.mentor? && current_user.team_id
          return relationship.user == current_user && relationship.relationship_type == "mentor"
        end

        false
      end
    end
  end
end
