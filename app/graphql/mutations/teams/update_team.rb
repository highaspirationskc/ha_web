# frozen_string_literal: true

module Mutations
  module Teams
    class UpdateTeam < AuthenticatedMutation
      description "Update an existing team"

      argument :input, Types::UpdateTeamInput, required: true

      field :team, Types::TeamType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        team = Team.find_by(id: input[:id])

        return { team: nil, errors: ["Team not found"] } unless team

        if team.update(input.to_h.except(:id))
          { team: team, errors: [] }
        else
          { team: nil, errors: team.errors.full_messages }
        end
      end
    end
  end
end
