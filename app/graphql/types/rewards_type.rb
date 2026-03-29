# frozen_string_literal: true

module Types
  class RewardsType < Types::BaseObject
    field :individual_incentives, [Types::IncentiveType], null: false
    field :team_incentives, [Types::IncentiveType], null: false
    field :redeemed, [Types::RedemptionType], null: false
    field :total_points, Integer, null: false
  end
end
