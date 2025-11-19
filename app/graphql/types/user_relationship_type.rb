# frozen_string_literal: true

module Types
  class UserRelationshipType < Types::BaseObject
    field :id, ID, null: false
    field :relationship_type, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :user, Types::UserType, null: false
    field :related_user, Types::UserType, null: false
  end
end
