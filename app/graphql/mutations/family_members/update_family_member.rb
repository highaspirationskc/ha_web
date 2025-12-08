# frozen_string_literal: true

module Mutations
  module FamilyMembers
    class UpdateFamilyMember < AuthenticatedMutation
      description "Update an existing family member relationship"

      argument :input, Types::UpdateFamilyMemberInput, required: true

      field :family_member, Types::FamilyMemberType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        family_member = FamilyMember.find_by(id: input[:id])

        return { family_member: nil, errors: ["Family member not found"] } unless family_member

        unless staff_member?
          return { family_member: nil, errors: ["You don't have permission to update this relationship"] }
        end

        if family_member.update(input.to_h.except(:id))
          { family_member: family_member, errors: [] }
        else
          { family_member: nil, errors: family_member.errors.full_messages }
        end
      end

      private

      def staff_member?
        current_user.staff.present?
      end
    end
  end
end
