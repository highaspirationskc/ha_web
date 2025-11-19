# frozen_string_literal: true

module Mutations
  module EventTypes
    class DeleteEventType < AuthenticatedMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        event_type = ::EventType.find_by(id: id)

        return { success: false, errors: ["Event type not found"] } unless event_type

        if event_type.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: event_type.errors.full_messages }
        end
      end
    end
  end
end
