# frozen_string_literal: true

module Mutations
  module CommunityServiceRecords
    class UpdateCommunityServiceRecord < AuthenticatedMutation
      description "Update a community service record (approve/deny)"

      argument :id, ID, required: true
      argument :approved, Boolean, required: false
      argument :event, String, required: false
      argument :description, String, required: false
      argument :event_date, GraphQL::Types::ISO8601Date, required: false
      argument :hours, Float, required: false

      field :community_service_record, Types::CommunityServiceRecordType, null: true
      field :errors, [String], null: false

      def resolve(id:, **attributes)
        record = find_accessible_record(id)

        unless record
          return { community_service_record: nil, errors: ["Record not found"] }
        end

        if record.update(attributes.compact)
          { community_service_record: record, errors: [] }
        else
          { community_service_record: nil, errors: record.errors.full_messages }
        end
      end

      private

      def find_accessible_record(id)
        if current_user.admin? || current_user.staff?
          CommunityServiceRecord.find_by(id: id)
        elsif current_user.mentor
          CommunityServiceRecord.joins(:mentee)
            .where(mentees: { mentor_id: current_user.mentor.id })
            .find_by(id: id)
        end
      end
    end
  end
end
