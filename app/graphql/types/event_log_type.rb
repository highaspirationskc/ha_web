# frozen_string_literal: true

module Types
  class EventLogType < Types::BaseObject
    field :id, ID, null: false
    field :participated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :points_awarded, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :event, Types::EventType, null: false
    field :user, Types::UserType, null: false
  end
end
