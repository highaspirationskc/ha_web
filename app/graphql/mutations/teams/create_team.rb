# frozen_string_literal: true

module Mutations
  module Teams
    class CreateTeam < AuthenticatedMutation
      argument :input, Types::CreateTeamInput, required: true

      field :team, Types::TeamType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        team = Team.new(input.to_h)

        if team.save
          { team: team, errors: [] }
        else
          { team: nil, errors: team.errors.full_messages }
        end
      end
    end
  end
end
