# frozen_string_literal: true

module Types
  class MentorType < Types::BaseObject
    field :id, ID, null: false
    field :user, Types::UserType, null: false
    field :mentees, [Types::MenteeType], null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
