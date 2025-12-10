# frozen_string_literal: true

module Types
  class SaturdayScoopType < Types::BaseObject
    field :id, ID, null: false
    field :title, String, null: false
    field :author, String, null: false
    field :description, String, null: true
    field :publish_on, GraphQL::Types::ISO8601Date, null: true
    field :published, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :image_url, String, null: true
    def image_url
      object.image&.url
    end

    field :image_thumbnail_url, String, null: true
    def image_thumbnail_url
      object.image&.thumbnail_url
    end

    field :video_url, String, null: true
    def video_url
      object.video&.url
    end

    field :video_embed_url, String, null: true
    def video_embed_url
      object.video&.embed_url
    end

    field :video_thumbnail_url, String, null: true
    def video_thumbnail_url
      object.video&.thumbnail_url
    end
  end
end
