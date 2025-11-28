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
    field :event_logs, [Types::EventLogType], null: false
    field :family_members, [Types::FamilyMemberType], null: false

    # Team-based relationships (for mentors/volunteers)
    field :team_mentees, [Types::UserType], null: false, description: "Mentees on the same team (for mentors/volunteers)"

    # Parent-child relationships (via FamilyMember)
    field :parents, [Types::UserType], null: false, description: "Parents/guardians of this mentee"
    field :children, [Types::UserType], null: false, description: "Children (mentees) of this parent"
  end
end
