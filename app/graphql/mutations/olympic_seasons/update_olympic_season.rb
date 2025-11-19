# frozen_string_literal: true

module Mutations
  module OlympicSeasons
    class UpdateOlympicSeason < AuthenticatedMutation
      description "Update an existing olympic season"

      argument :input, Types::UpdateOlympicSeasonInput, required: true

      field :olympic_season, Types::OlympicSeasonType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        olympic_season = OlympicSeason.find_by(id: input[:id])

        return { olympic_season: nil, errors: ["Olympic season not found"] } unless olympic_season

        if olympic_season.update(input.to_h.except(:id))
          { olympic_season: olympic_season, errors: [] }
        else
          { olympic_season: nil, errors: olympic_season.errors.full_messages }
        end
      end
    end
  end
end
