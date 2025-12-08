# frozen_string_literal: true

module Types
  class UserType < Types::BaseObject
    field :id, ID, null: false
    field :email, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :active, Boolean, null: false
    field :avatar_url, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # Role profiles
    field :mentor, Types::MentorType, null: true
    field :mentee, Types::MenteeType, null: true
    field :guardian, Types::GuardianType, null: true
    field :staff, Types::StaffType, null: true
    field :volunteer, Types::VolunteerType, null: true

    field :created_events, [Types::EventType], null: false
    field :event_logs, [Types::EventLogType], null: false
  end
end
