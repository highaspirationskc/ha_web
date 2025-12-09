module Mutations
  module Messages
    class ComposeMessage < AuthenticatedMutation
      description "Compose and send a new message"

      argument :input, Types::ComposeMessageInput, required: true

      field :message, Types::MessageType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        recipient_ids = input[:recipient_ids].map(&:to_i)
        recipients = User.where(id: recipient_ids)

        if recipients.empty?
          return { message: nil, errors: ["At least one recipient is required"] }
        end

        unauthorized_recipients = recipients.reject do |recipient|
          Authorization.can_message?(current_user, recipient)
        end

        if unauthorized_recipients.any?
          names = unauthorized_recipients.map { |u| "#{u.first_name} #{u.last_name}" }.join(", ")
          return { message: nil, errors: ["You are not authorized to message: #{names}"] }
        end

        message = Message.new(
          author: current_user,
          subject: input[:subject],
          message: input[:message],
          reply_mode: input[:reply_mode],
          support: input[:support]
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
    end
  end
end
