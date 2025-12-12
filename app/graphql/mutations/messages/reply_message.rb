module Mutations
  module Messages
    class ReplyMessage < AuthenticatedMutation
      description "Reply to an existing message"

      argument :input, Types::ReplyMessageInput, required: true

      field :message, Types::MessageType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        parent = Message.find_by(id: input[:parent_id])

        unless parent
          return { message: nil, errors: ["Message not found"] }
        end

        unless can_reply_to?(parent)
          return { message: nil, errors: ["You are not authorized to reply to this message"] }
        end

        if parent.no_replies?
          return { message: nil, errors: ["Replies are not allowed for this message"] }
        end

        subject = parent.subject.start_with?("Re: ") ? parent.subject : "Re: #{parent.subject}"
        recipients = determine_recipients(parent)

        message = Message.new(
          author: current_user,
          parent: parent.thread_root,
          subject: subject,
          message: input[:message],
          reply_mode: parent.reply_mode,
          support: parent.support
        )

        if message.save
          recipients.each do |recipient|
            MessageRecipient.create!(message: message, recipient: recipient)
          end
          message.broadcast_to_recipients
          { message: message, errors: [] }
        else
          { message: nil, errors: message.errors.full_messages }
        end
      end

      private

      def can_reply_to?(message)
        return true if current_user.can?(:reply_any, :messages)

        message.thread_participants.include?(current_user)
      end

      def determine_recipients(parent)
        if parent.reply_to_all?
          parent.thread_participants.reject { |u| u == current_user }
        else
          [parent.author]
        end
      end
    end
  end
end
