# frozen_string_literal: true

module Mutations
  module Users
    class DeleteUser < AuthenticatedMutation
      description "Delete a user (superuser only)"

      argument :id, ID, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(id:)
        unless superuser?
          return { success: false, errors: ["You don't have permission to delete users"] }
        end

        user = User.find_by(id: id)

        return { success: false, errors: ["User not found"] } unless user

        if user.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: user.errors.full_messages }
        end
      end

      private

      def superuser?
        current_user.staff.present?
      end
    end
  end
end
