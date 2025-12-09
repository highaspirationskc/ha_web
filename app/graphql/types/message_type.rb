module Types
  class MessageType < Types::BaseObject
    field :id, ID, null: false
    field :subject, String, null: false
    field :message, String, null: false
    field :reply_mode, String, null: false
    field :support, Boolean, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    field :author, Types::UserType, null: false
    field :recipients, [Types::UserType], null: false
    field :parent, Types::MessageType, null: true
    field :replies, [Types::MessageType], null: false
    field :thread_root, Types::MessageType, null: false

    field :is_reply, Boolean, null: false

    def is_reply
      object.reply?
    end
  end
end
