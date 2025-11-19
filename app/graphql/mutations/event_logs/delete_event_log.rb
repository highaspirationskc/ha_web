# frozen_string_literal: true

module Mutations
  module EventLogs
    class DeleteEventLog < AuthenticatedMutation
      field :success, Boolean, null: false
      field :errors, [String], null: false

      argument :id, ID, required: true

      def resolve(id:)
        event_log = EventLog.find_by(id: id)

        return { success: false, errors: ["Event log not found"] } unless event_log

        if event_log.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: event_log.errors.full_messages }
        end
      end
    end
  end
end
