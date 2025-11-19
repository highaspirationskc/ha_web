# frozen_string_literal: true

module Types
  class EventType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :event_date, GraphQL::Types::ISO8601DateTime, null: false
    field :location, String, null: true
    field :image_url, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :event_type, Types::EventTypeType, null: false
    field :created_by, Types::UserType, null: false
    field :event_registrations, [Types::EventRegistrationType], null: false
    field :event_logs, [Types::EventLogType], null: false
    field :users, [Types::UserType], null: false
    field :olympic_season, Types::OlympicSeasonType, null: true
  end
end
