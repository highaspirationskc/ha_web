# frozen_string_literal: true

module Mutations
  module Redemptions
    class CreateRedemption < AuthenticatedMutation
      description "Create a new incentive redemption request"

      argument :incentive_id, ID, required: true

      field :redemption, Types::RedemptionType, null: true
      field :errors, [String], null: false

      def resolve(incentive_id:)
        unless current_user.mentee
          raise GraphQL::ExecutionError, "Only mentees can create redemptions"
        end

        incentive = Incentive.active.find_by(id: incentive_id)
        unless incentive
          return { redemption: nil, errors: ["Incentive not found or inactive"] }
        end

        mentee = current_user.mentee
        if mentee.total_points < incentive.point_cost
          return { redemption: nil, errors: ["Not enough points (#{mentee.total_points} available, #{incentive.point_cost} required)"] }
        end

        redemption = mentee.redemptions.build(
          incentive: incentive,
          points_spent: incentive.point_cost,
          status: "pending"
        )

        if redemption.save
          { redemption: redemption, errors: [] }
        else
          { redemption: nil, errors: redemption.errors.full_messages }
        end
      end
    end
  end
end
