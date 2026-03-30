# frozen_string_literal: true

module Mutations
  module Redemptions
    class CreateRedemption < AuthenticatedMutation
      description "Create a new incentive redemption request"

      argument :incentive_id, ID, required: true

      field :redemption, Types::RedemptionType, null: true
      field :errors, [String], null: false

      def resolve(incentive_id:)
        result = CreateRedemptionService.new(context[:current_user]).create(incentive_id: incentive_id)

        if result.success?
          { redemption: result.redemption, errors: [] }
        else
          { redemption: nil, errors: result.errors }
        end
      end
    end
  end
end
