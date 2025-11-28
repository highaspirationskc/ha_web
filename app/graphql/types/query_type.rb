# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Authenticated queries

    # Teams
    field :teams, [Types::TeamType], null: false, description: "List all teams"
    def teams
      require_authentication!
      Team.all
    end

    field :team, Types::TeamType, null: true, description: "Get a team by ID" do
      argument :id, ID, required: true
    end
    def team(id:)
      require_authentication!
      Team.find_by(id: id)
    end

    # Events
    field :events, [Types::EventType], null: false, description: "List events with optional date filtering" do
      argument :input, Types::EventsFilterInput, required: false
    end
    def events(input: nil)
      require_authentication!
      scope = Event.all

      if input
        start_date = input[:start_date] || Date.current

        if input[:end_date]
          end_date = input[:end_date]
        else
          # Find current olympic season and use its end date
          current_season = find_current_olympic_season(start_date)
          if current_season
            end_date = calculate_season_end_date(current_season, start_date.year)
          else
            # If no season found, return all future events
            end_date = nil
          end
        end

        scope = scope.where("event_date >= ?", start_date)
        scope = scope.where("event_date <= ?", end_date) if end_date
      end

      scope.order(event_date: :asc)
    end

    field :event, Types::EventType, null: true, description: "Get an event by ID" do
      argument :id, ID, required: true
    end
    def event(id:)
      require_authentication!
      Event.find_by(id: id)
    end

    # Event Types
    field :event_types, [Types::EventTypeType], null: false, description: "List all event types"
    def event_types
      require_authentication!
      ::EventType.all
    end

    field :event_type, Types::EventTypeType, null: true, description: "Get an event type by ID" do
      argument :id, ID, required: true
    end
    def event_type(id:)
      require_authentication!
      ::EventType.find_by(id: id)
    end

    # Olympic Seasons
    field :olympic_seasons, [Types::OlympicSeasonType], null: false, description: "List all olympic season templates"
    def olympic_seasons
      require_authentication!
      OlympicSeason.all
    end

    field :olympic_season, Types::OlympicSeasonType, null: true, description: "Get olympic season by name and year, or current season if no args" do
      argument :input, Types::OlympicSeasonQueryInput, required: false
    end
    def olympic_season(input: nil)
      require_authentication!

      season = if input && input[:name]
        # Find by name
        OlympicSeason.find_by(name: input[:name])
      else
        # Find current season
        find_current_olympic_season(Date.current)
      end

      # Attach the year from input if provided (for filtering events)
      season.current_year = input[:year] if season && input && input[:year]

      season
    end

    # Event Logs
    field :event_logs, [Types::EventLogType], null: false, description: "List all event logs"
    def event_logs
      require_authentication!
      EventLog.all
    end

    field :event_log, Types::EventLogType, null: true, description: "Get an event log by ID" do
      argument :id, ID, required: true
    end
    def event_log(id:)
      require_authentication!
      EventLog.find_by(id: id)
    end

    # Family Members
    field :family_members, [Types::FamilyMemberType], null: false, description: "List all family member relationships"
    def family_members
      require_authentication!
      FamilyMember.all
    end

    field :family_member, Types::FamilyMemberType, null: true, description: "Get a family member by ID" do
      argument :id, ID, required: true
    end
    def family_member(id:)
      require_authentication!
      FamilyMember.find_by(id: id)
    end

    # Users
    field :users, [Types::UserType], null: false, description: "List all users"
    def users
      require_authentication!
      User.all
    end

    field :user, Types::UserType, null: true, description: "Get a user by ID" do
      argument :id, ID, required: true
    end
    def user(id:)
      require_authentication!
      User.find_by(id: id)
    end

    field :current_user, Types::UserType, null: true, description: "Get the currently authenticated user"
    def current_user
      require_authentication!
      context[:current_user]
    end

    private

    def require_authentication!
      return if context[:current_user]
      raise GraphQL::ExecutionError, "Authentication required"
    end

    def find_current_olympic_season(date)
      OlympicSeason.all.find do |season|
        OlympicSeasonService.new(season).includes_date?(date)
      end
    end

    def calculate_season_end_date(season, year)
      OlympicSeasonService.new(season).end_date(year)
    end
  end
end
