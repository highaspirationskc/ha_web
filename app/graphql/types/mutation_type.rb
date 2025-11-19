# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    # Auth mutations (unauthenticated)
    field :register, mutation: Mutations::Register
    field :login, mutation: Mutations::Login
    field :logout, mutation: Mutations::Logout

    # Team mutations
    field :create_team, mutation: Mutations::Teams::CreateTeam
    field :update_team, mutation: Mutations::Teams::UpdateTeam
    field :delete_team, mutation: Mutations::Teams::DeleteTeam

    # Event mutations
    field :create_event, mutation: Mutations::Events::CreateEvent
    field :update_event, mutation: Mutations::Events::UpdateEvent
    field :delete_event, mutation: Mutations::Events::DeleteEvent

    # Event Type mutations
    field :create_event_type, mutation: Mutations::EventTypes::CreateEventType
    field :update_event_type, mutation: Mutations::EventTypes::UpdateEventType
    field :delete_event_type, mutation: Mutations::EventTypes::DeleteEventType

    # Olympic Season mutations
    field :create_olympic_season, mutation: Mutations::OlympicSeasons::CreateOlympicSeason
    field :update_olympic_season, mutation: Mutations::OlympicSeasons::UpdateOlympicSeason
    field :delete_olympic_season, mutation: Mutations::OlympicSeasons::DeleteOlympicSeason

    # Event Registration mutations
    field :create_event_registration, mutation: Mutations::EventRegistrations::CreateEventRegistration
    field :update_event_registration, mutation: Mutations::EventRegistrations::UpdateEventRegistration
    field :delete_event_registration, mutation: Mutations::EventRegistrations::DeleteEventRegistration

    # Event Log mutations
    field :create_event_log, mutation: Mutations::EventLogs::CreateEventLog
    field :update_event_log, mutation: Mutations::EventLogs::UpdateEventLog
    field :delete_event_log, mutation: Mutations::EventLogs::DeleteEventLog

    # User Relationship mutations
    field :create_user_relationship, mutation: Mutations::UserRelationships::CreateUserRelationship
    field :update_user_relationship, mutation: Mutations::UserRelationships::UpdateUserRelationship
    field :delete_user_relationship, mutation: Mutations::UserRelationships::DeleteUserRelationship
  end
end
