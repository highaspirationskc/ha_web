# frozen_string_literal: true

module Mutations
  module OlympicSeasons
    class DeleteOlympicSeason < AuthenticatedMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        olympic_season = OlympicSeason.find_by(id: id)

        return { success: false, errors: ["Olympic season not found"] } unless olympic_season

        if olympic_season.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: olympic_season.errors.full_messages }
        end
      end
    end
  end
end
