# frozen_string_literal: true

module Mutations
  module FamilyMembers
    class CreateFamilyMember < AuthenticatedMutation
      description "Create a new family member relationship"

      argument :input, Types::CreateFamilyMemberInput, required: true

      field :family_member, Types::FamilyMemberType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        guardian = Guardian.find_by(id: input[:guardian_id])
        mentee = Mentee.find_by(id: input[:mentee_id])

        return { family_member: nil, errors: ["Guardian not found"] } unless guardian
        return { family_member: nil, errors: ["Mentee not found"] } unless mentee

        # Check permissions - only staff can create family member relationships
        unless staff_member?
          return { family_member: nil, errors: ["You don't have permission to create this relationship"] }
        end

        family_member = FamilyMember.new(
          guardian: guardian,
          mentee: mentee,
          relationship_type: input[:relationship_type]
        )

        if family_member.save
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
