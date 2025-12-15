# frozen_string_literal: true

module Mutations
  module Messages
    class MarkThreadRead < AuthenticatedMutation
      description "Mark all messages in a thread as read for the current user"

      argument :message_id, ID, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(message_id:)
        service = MessagesService.new(current_user)
        result = service.mark_thread_read(message_id: message_id)

        if result.success?
          { success: true, errors: [] }
        else
          { success: false, errors: [result.error] }
        end
      end
    end
  end
end
