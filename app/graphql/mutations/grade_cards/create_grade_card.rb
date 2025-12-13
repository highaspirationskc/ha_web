# frozen_string_literal: true

module Mutations
  module GradeCards
    class CreateGradeCard < AuthenticatedMutation
      description "Create a new grade card for a mentee"

      argument :input, Types::CreateGradeCardInput, required: true

      field :grade_card, Types::GradeCardType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        mentee = Mentee.find_by(id: input[:mentee_id])
        medium = Medium.find_by(id: input[:medium_id])

        result = GradeCardsService.new(current_user).create(
          mentee: mentee,
          medium: medium,
          description: input[:description]
        )

        if result.success?
          { grade_card: result.grade_card, errors: [] }
        elsif result.error&.include?("permission")
          raise GraphQL::ExecutionError, result.error
        else
          { grade_card: nil, errors: [result.error] }
        end
      end
    end
  end
end
