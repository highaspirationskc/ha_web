# frozen_string_literal: true

module Mutations
  module Events
    class DeleteEvent < AuthenticatedMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        event = Event.find_by(id: id)

        return { success: false, errors: ["Event not found"] } unless event

        if event.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: event.errors.full_messages }
        end
      end
    end
  end
end
