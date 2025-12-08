# frozen_string_literal: true

module Types
  class FamilyMemberType < Types::BaseObject
    field :id, ID, null: false
    field :relationship_type, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :guardian, Types::GuardianType, null: false
    field :mentee, Types::MenteeType, null: false
  end
end
