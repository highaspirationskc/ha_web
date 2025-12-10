# frozen_string_literal: true

module Types
  class CommunityServiceRecordType < Types::BaseObject
    field :id, ID, null: false
    field :event, String, null: false
    field :description, String
    field :event_date, GraphQL::Types::ISO8601Date, null: false
    field :hours, Float, null: false
    field :approved, Boolean, null: false
    field :mentee, Types::MenteeType, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
