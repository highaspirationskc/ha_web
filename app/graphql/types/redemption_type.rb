# frozen_string_literal: true

module Types
  class RedemptionType < Types::BaseObject
    field :id, ID, null: false
    field :incentive, Types::IncentiveType, null: false
    field :mentee, Types::MenteeType, null: false
    field :points_spent, Integer, null: false
    field :status, String, null: false
    field :approved_by, Types::UserType, null: true
    field :approved_at, GraphQL::Types::ISO8601DateTime, null: true
    field :notes, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
