# frozen_string_literal: true

module Mutations
  module EventRegistrations
    class DeleteEventRegistration < AuthenticatedMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        event_registration = EventRegistration.find_by(id: id)

        return { success: false, errors: ["Event registration not found"] } unless event_registration

        if event_registration.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: event_registration.errors.full_messages }
        end
      end
    end
  end
end
