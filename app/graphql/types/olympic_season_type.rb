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
      # Use year from input if provided, otherwise default to current year
      year = object.current_year || Date.current.year

      # Use service to get date range
      service = OlympicSeasonService.new(object)
      date_range = service.date_range(year)

      Event.where(event_date: date_range)
    end
  end
end
