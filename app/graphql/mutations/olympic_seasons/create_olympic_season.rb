# frozen_string_literal: true

module Mutations
  module OlympicSeasons
    class CreateOlympicSeason < AuthenticatedMutation
      description "Create a new olympic season"

      argument :input, Types::CreateOlympicSeasonInput, required: true

      field :olympic_season, Types::OlympicSeasonType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        olympic_season = OlympicSeason.new(input.to_h)

        if olympic_season.save
          { olympic_season: olympic_season, errors: [] }
        else
          { olympic_season: nil, errors: olympic_season.errors.full_messages }
        end
      end
    end
  end
end
