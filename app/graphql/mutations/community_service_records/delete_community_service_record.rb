# frozen_string_literal: true

module Mutations
  module CommunityServiceRecords
    class DeleteCommunityServiceRecord < AuthenticatedMutation
      description "Delete a community service record"

      argument :id, ID, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(id:)
        unless current_user.admin? || current_user.staff?
          raise GraphQL::ExecutionError, "Only staff can delete community service records"
        end

        record = CommunityServiceRecord.find_by(id: id)

        unless record
          return { success: false, errors: ["Record not found"] }
        end

        if record.destroy
          { success: true, errors: [] }
        else
          { success: false, errors: record.errors.full_messages }
        end
      end
    end
  end
end
