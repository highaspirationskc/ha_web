# frozen_string_literal: true

module Types
  class TeamType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :color, String, null: false
    field :icon_url, String, null: true
    def icon_url
      object.icon&.thumbnail_url
    end
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :members, [Types::UserType], null: false
    field :mentees, [Types::UserType], null: false
    field :parents, [Types::UserType], null: false
    field :mentors, [Types::UserType], null: false
    field :event_logs, [Types::EventLogType], null: false
    field :total_points, Integer, null: false, description: "Total points for current Olympic season"
    field :total_community_service_hours, Float, null: false, description: "Total approved community service hours for current Olympic season"
  end
end
