# frozen_string_literal: true

module Mutations
  module Users
    class UpdateUser < AuthenticatedMutation
      description "Update an existing user (superuser only, or self for limited fields)"

      argument :input, Types::UpdateUserInput, required: true

      field :user, Types::UserType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        user = User.find_by(id: input[:id])

        return { user: nil, errors: ["User not found"] } unless user

        # Check permissions
        unless can_update?(user, input)
          return { user: nil, errors: ["You don't have permission to update this user"] }
        end

        # Filter allowed attributes based on permissions
        permitted_attrs = permitted_attributes(user, input)

        if user.update(permitted_attrs)
          { user: user, errors: [] }
        else
          { user: nil, errors: user.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.staff.present?
      end

      def can_update?(user, input)
        return true if superuser?
        return true if user.id == current_user.id && self_update_only?(input)
        false
      end

      def self_update_only?(input)
        # Non-superusers can only update their own password
        input.to_h.except(:id).keys.all? { |k| [:password, :avatar_id, :email, :first_name, :last_name, :phone_number].include?(k) }
      end

      def permitted_attributes(user, input)
        attrs = input.to_h.except(:id)

        if superuser?
          attrs
        else
          # Non-superusers can only update password
          attrs.slice(:password, :avatar_id, :email, :first_name, :last_name, :phone_number)
        end
      end
    end
  end
end
