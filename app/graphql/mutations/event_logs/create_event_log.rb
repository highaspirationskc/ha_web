# frozen_string_literal: true

module Mutations
  module EventLogs
    class CreateEventLog < AuthenticatedMutation
      description "Create a new event log"

      argument :input, Types::CreateEventLogInput, required: true

      field :event_log, Types::EventLogType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event_log = EventLog.new(input.to_h)

        if event_log.save
          { event_log: event_log, errors: [] }
        else
          { event_log: nil, errors: event_log.errors.full_messages }
        end
      end
    end
  end
end
