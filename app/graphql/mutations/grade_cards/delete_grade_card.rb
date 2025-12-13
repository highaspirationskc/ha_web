# frozen_string_literal: true

module Mutations
  module GradeCards
    class DeleteGradeCard < AuthenticatedMutation
      description "Delete a grade card"

      argument :id, ID, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(id:)
        service = GradeCardsService.new(current_user)
        grade_card = service.find(id)

        result = service.delete(grade_card)

        if result.success?
          { success: true, errors: [] }
        elsif result.error&.include?("permission")
          raise GraphQL::ExecutionError, result.error
        else
          { success: false, errors: [result.error] }
        end
      end
    end
  end
end
