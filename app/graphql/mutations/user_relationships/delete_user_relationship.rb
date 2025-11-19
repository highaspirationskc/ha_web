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

        if user_relationship.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: user_relationship.errors.full_messages }
        end
      end
    end
  end
end
