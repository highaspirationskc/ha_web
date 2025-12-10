# frozen_string_literal: true

module Mutations
  module CommunityServiceRecords
    class CreateCommunityServiceRecord < AuthenticatedMutation
      description "Create a new community service record"

      argument :event, String, required: true
      argument :description, String, required: false
      argument :event_date, GraphQL::Types::ISO8601Date, required: true
      argument :hours, Float, required: true

      field :community_service_record, Types::CommunityServiceRecordType, null: true
      field :errors, [String], null: false

      def resolve(event:, event_date:, hours:, description: nil)
        unless current_user.mentee
          raise GraphQL::ExecutionError, "Only mentees can create community service records"
        end

        record = current_user.mentee.community_service_records.build(
          event: event,
          description: description,
          event_date: event_date,
          hours: hours
        )

        if record.save
          { community_service_record: record, errors: [] }
        else
          { community_service_record: nil, errors: record.errors.full_messages }
        end
      end
    end
  end
end
