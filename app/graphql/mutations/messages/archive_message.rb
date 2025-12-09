module Mutations
  module Messages
    class ArchiveMessage < AuthenticatedMutation
      description "Archive a message for the current user"

      argument :message_id, ID, required: true
      argument :archive, Boolean, required: false, default_value: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(message_id:, archive:)
        message = Message.find_by(id: message_id)

        unless message
          return { success: false, errors: ["Message not found"] }
        end

        recipient = MessageRecipient.find_by(
          message: message,
          recipient: current_user
        )

        unless recipient
          return { success: false, errors: ["You are not a recipient of this message"] }
        end

        if archive
          recipient.archive!
        else
          recipient.unarchive!
        end

        { success: true, errors: [] }
      end
    end
  end
end
