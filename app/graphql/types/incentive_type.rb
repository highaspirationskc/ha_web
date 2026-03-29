# frozen_string_literal: true

module Types
  class IncentiveType < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :description, String
    field :point_cost, Integer, null: false
    field :incentive_type, String, null: false
    field :active, Boolean, null: false
    field :image_url, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def image_url
      object.image&.url
    end
  end
end
