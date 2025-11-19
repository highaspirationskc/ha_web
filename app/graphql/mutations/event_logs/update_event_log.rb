# frozen_string_literal: true

module Mutations
  module EventLogs
    class UpdateEventLog < AuthenticatedMutation
      description "Update an existing event log"

      argument :input, Types::UpdateEventLogInput, required: true

      field :event_log, Types::EventLogType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        event_log = EventLog.find_by(id: input[:id])

        return { event_log: nil, errors: ["Event log not found"] } unless event_log

        if event_log.update(input.to_h.except(:id))
          { event_log: event_log, errors: [] }
        else
          { event_log: nil, errors: event_log.errors.full_messages }
        end
      end
    end
  end
end
