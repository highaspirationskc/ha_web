# frozen_string_literal: true

module Types
  class GradeCardType < Types::BaseObject
    field :id, ID, null: false
    field :description, String
    field :mentee, Types::MenteeType, null: false
    field :image_url, String, null: false
    field :thumbnail_url, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def image_url
      object.medium.url
    end

    def thumbnail_url
      object.medium.thumbnail_url
    end
  end
end
