module Mutations
  module Messages
    class MarkThreadRead < AuthenticatedMutation
      description "Mark all messages in a thread as read for the current user"

      argument :message_id, ID, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(message_id:)
        message = Message.find_by(id: message_id)

        unless message
          return { success: false, errors: ["Message not found"] }
        end

        thread_root = message.thread_root
        thread_message_ids = thread_root.thread_messages.pluck(:id)

        MessageRecipient.where(
          message_id: thread_message_ids,
          recipient: current_user
        ).update_all(is_read: true)

        { success: true, errors: [] }
      end
    end
  end
end
