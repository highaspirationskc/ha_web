# frozen_string_literal: true

module Mutations
  module EventLogs
    class Unregister < AuthenticatedMutation
      description "Unregister the current user from an event"

      argument :input, Types::RegisterInput, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(input:)
        event = Event.find_by(id: input[:event_id])

        unless event
          return { success: false, errors: ["Event not found"] }
        end

        event_log = EventLog.find_by(
          event: event,
          user: current_user,
          log_type: :registered
        )

        unless event_log
          return { success: false, errors: ["You are not registered for this event"] }
        end

        if event_log.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: event_log.errors.full_messages }
        end
      end
    end
  end
end
