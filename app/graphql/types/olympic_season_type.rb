# frozen_string_literal: true

module Types
  class OlympicSeasonType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :start_month, Integer, null: false
    field :start_day, Integer, null: false
    field :end_month, Integer, null: false
    field :end_day, Integer, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :events, [Types::EventType], null: false, description: "Events for this season (filtered by year from query input)"

    def events
      Event.all.order(event_date: :asc)
    end
  end
end
