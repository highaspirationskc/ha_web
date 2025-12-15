# frozen_string_literal: true

module Types
  class RecipientGroupType < Types::BaseObject
    description "A group recipient option for messaging"

    field :id, String, null: false, description: "Group identifier (e.g., 'support', 'group:staff')"
    field :name, String, null: false, description: "Display name for the group"
    field :description, String, null: true, description: "Description of who is in this group"
  end
end
