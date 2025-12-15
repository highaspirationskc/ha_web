# frozen_string_literal: true

module Mutations
  module Messages
    class ComposeMessage < AuthenticatedMutation
      description "Compose and send a new message"

      argument :input, Types::ComposeMessageInput, required: true

      field :message, Types::MessageType, null: true
      field :messages, [Types::MessageType], null: true
      field :errors, [String], null: false

      def resolve(input:)
        service = MessagesService.new(current_user)
        result = service.compose(
          subject: input[:subject],
          body: input[:message],
          recipient_ids: input[:recipient_ids],
          reply_mode: input[:reply_mode],
          support: input[:support]
        )

        if result.success?
          {
            message: result.message,
            messages: result.messages,
            errors: []
          }
        else
          { message: nil, messages: nil, errors: [result.error] }
        end
      end
    end
  end
end
