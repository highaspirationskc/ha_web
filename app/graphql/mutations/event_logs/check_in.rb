# frozen_string_literal: true

module Mutations
  module EventLogs
    class CheckIn < AuthenticatedMutation
      description "Check in the current user to an event"

      argument :input, Types::CheckInInput, required: true

      field :event_log, Types::EventLogType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event = Event.find_by(id: input[:event_id])

        unless event
          return { event_log: nil, errors: ["Event not found"] }
        end

        event_log = EventLog.new(
          event: event,
          user: current_user,
          log_type: :arrived
        )

        if event_log.save
          { event_log: event_log, errors: [] }
        else
          { event_log: nil, errors: event_log.errors.full_messages }
        end
      end
    end
  end
end
