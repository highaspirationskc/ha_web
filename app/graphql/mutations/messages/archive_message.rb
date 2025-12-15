# frozen_string_literal: true

module Mutations
  module Messages
    class ArchiveMessage < AuthenticatedMutation
      description "Archive or unarchive an entire message thread for the current user"

      argument :message_id, ID, required: true
      argument :archive, Boolean, required: false, default_value: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(message_id:, archive:)
        service = MessagesService.new(current_user)

        result = if archive
          service.archive(message_id: message_id)
        else
          service.unarchive(message_id: message_id)
        end

        if result.success?
          { success: true, errors: [] }
        else
          { success: false, errors: [result.error] }
        end
      end
    end
  end
end
