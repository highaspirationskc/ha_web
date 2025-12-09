module Types
  class MessageRecipientType < Types::BaseObject
    field :id, ID, null: false
    field :is_read, Boolean, null: false
    field :archived, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    field :message, Types::MessageType, null: false
    field :recipient, Types::UserType, null: false
  end
end
