# frozen_string_literal: true

module Types
  class TeamType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :color, String, null: false
    field :icon_url, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :members, [Types::UserType], null: false
    field :mentees, [Types::UserType], null: false
    field :parents, [Types::UserType], null: false
    field :mentors, [Types::UserType], null: false
    field :event_logs, [Types::EventLogType], null: false
  end
end
