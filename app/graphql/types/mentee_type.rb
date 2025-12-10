# frozen_string_literal: true

module Types
  class MenteeType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :mentor, Types::MentorType, null: true
    field :team, Types::TeamType, null: true
    field :guardians, [Types::GuardianType], null: false
    field :total_points, Integer, null: false, description: "Total points for current Olympic season"
    field :community_service_records, [Types::CommunityServiceRecordType], null: false
    field :total_community_service_hours, Float, null: false, description: "Total approved community service hours for current Olympic season"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
