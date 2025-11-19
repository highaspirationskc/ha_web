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

      # Build date range for this season in the specified year
      start_date = Date.new(year, object.start_month, object.start_day)

      # Handle year-spanning seasons (e.g., Winter Dec-Feb)
      end_year = if object.start_month > object.end_month
        year + 1
      else
        year
      end

      end_date = Date.new(end_year, object.end_month, object.end_day)

      Event.where(event_date: start_date..end_date)
    end
  end
end
