# frozen_string_literal: true

module Types
  class ComposeRecipientsType < Types::BaseObject
    description "Available recipients for composing a message"

    field :users, [Types::UserType], null: false, description: "Individual users that can be messaged"
    field :groups, [Types::RecipientGroupType], null: false, description: "Group recipients available (varies by user role)"
  end
end
