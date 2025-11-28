# frozen_string_literal: true

module Mutations
  module FamilyMembers
    class DeleteFamilyMember < AuthenticatedMutation
      description "Delete a family member relationship"

      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        family_member = FamilyMember.find_by(id: id)

        return { success: false, errors: ["Family member not found"] } unless family_member

        unless superuser?
          return { success: false, errors: ["You don't have permission to delete this relationship"] }
        end

        if family_member.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: family_member.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.admin? || current_user.staff?
      end
    end
  end
end
