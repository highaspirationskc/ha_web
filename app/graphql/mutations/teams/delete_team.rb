# frozen_string_literal: true

module Mutations
  module Teams
    class DeleteTeam < AuthenticatedMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        team = Team.find_by(id: id)

        return { success: false, errors: ["Team not found"] } unless team

        if team.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: team.errors.full_messages }
        end
      end
    end
  end
end
