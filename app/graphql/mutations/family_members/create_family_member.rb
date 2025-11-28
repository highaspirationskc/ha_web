# frozen_string_literal: true

module Mutations
  module FamilyMembers
    class CreateFamilyMember < AuthenticatedMutation
      description "Create a new family member relationship"

      argument :input, Types::CreateFamilyMemberInput, required: true

      field :family_member, Types::FamilyMemberType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        user = User.find_by(id: input[:user_id])
        related_user = User.find_by(id: input[:related_user_id])

        return { family_member: nil, errors: ["User not found"] } unless user
        return { family_member: nil, errors: ["Related user not found"] } unless related_user

        # Check permissions - only superusers can create family member relationships
        unless superuser?
          return { family_member: nil, errors: ["You don't have permission to create this relationship"] }
        end

        family_member = FamilyMember.new(input.to_h)

        if family_member.save
          { family_member: family_member, errors: [] }
        else
          { family_member: nil, errors: family_member.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.admin? || current_user.staff?
      end
    end
  end
end
