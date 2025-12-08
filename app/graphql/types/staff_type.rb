# frozen_string_literal: true

module Types
  class StaffType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :permission_level, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
