# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    # Auth mutations (unauthenticated)
    field :register, mutation: Mutations::Register
    field :login, mutation: Mutations::Login
    field :logout, mutation: Mutations::Logout

    # User mutations
    field :create_user, mutation: Mutations::Users::CreateUser
    field :update_user, mutation: Mutations::Users::UpdateUser
    field :delete_user, mutation: Mutations::Users::DeleteUser

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

    # Event Log mutations
    field :create_event_log, mutation: Mutations::EventLogs::CreateEventLog
    field :update_event_log, mutation: Mutations::EventLogs::UpdateEventLog
    field :delete_event_log, mutation: Mutations::EventLogs::DeleteEventLog

    # Family Member mutations
    field :create_family_member, mutation: Mutations::FamilyMembers::CreateFamilyMember
    field :update_family_member, mutation: Mutations::FamilyMembers::UpdateFamilyMember
    field :delete_family_member, mutation: Mutations::FamilyMembers::DeleteFamilyMember
  end
end
