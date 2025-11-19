# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :role, String, null: false
    field :active, Boolean, null: false
    field :avatar_url, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :team, Types::TeamType, null: true
    field :created_events, [Types::EventType], null: false
    field :event_registrations, [Types::EventRegistrationType], null: false
    field :event_logs, [Types::EventLogType], null: false
    field :user_relationships, [Types::UserRelationshipType], null: false
    field :mentees, [Types::UserType], null: false
    field :mentors, [Types::UserType], null: false
    field :parents, [Types::UserType], null: false
    field :children, [Types::UserType], null: false
  end
end
