# frozen_string_literal: true

module Types
  class EventTypeType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :point_value, Integer, null: false
    field :category, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :events, [Types::EventType], null: false
  end
end
