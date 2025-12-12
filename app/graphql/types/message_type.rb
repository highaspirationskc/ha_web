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
    field :is_read, Boolean, null: false, description: "Whether the current user has read this message"

    def is_reply
      object.reply?
    end

    def is_read
      return true if context[:current_user].nil?

      recipient = object.message_recipients.find_by(recipient: context[:current_user])
      recipient&.is_read || false
    end
  end
end
