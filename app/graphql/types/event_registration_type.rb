# frozen_string_literal: true

module Types
  class EventRegistrationType < Types::BaseObject
    field :id, ID, null: false
    field :registration_date, GraphQL::Types::ISO8601DateTime, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :event, Types::EventType, null: false
    field :user, Types::UserType, null: false
  end
end
