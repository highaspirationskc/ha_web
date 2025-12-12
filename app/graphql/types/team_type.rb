# frozen_string_literal: true

module Types
  class TeamType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :color, String, null: false
    field :icon_url, String, null: true
    def icon_url
      object.icon&.thumbnail_url
    end
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :members, [Types::UserType], null: false
    field :mentees, [Types::UserType], null: false
    field :parents, [Types::UserType], null: false
    field :mentors, [Types::UserType], null: false
    field :event_logs, [Types::EventLogType], null: false
    field :total_points, Integer, null: false, description: "Total points for current Olympic season"
    field :total_community_service_hours, Float, null: false, description: "Total approved community service hours for current Olympic season"

    def mentees
      User.joins(:mentee).where(mentees: { team_id: object.id })
    end

    def mentors
      mentor_ids = object.mentees.where.not(mentor_id: nil).pluck(:mentor_id).uniq
      User.joins(:mentor).where(mentors: { id: mentor_ids })
    end

    def parents
      mentee_ids = object.mentees.pluck(:id)
      User.joins(guardian: :family_members).where(family_members: { mentee_id: mentee_ids }).distinct
    end

    def members
      mentees + mentors + parents
    end

    def event_logs
      EventLog.joins(user: :mentee).where(mentees: { team_id: object.id })
    end
  end
end
