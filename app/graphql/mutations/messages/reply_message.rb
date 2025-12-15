# frozen_string_literal: true

module Mutations
  module Messages
    class ReplyMessage < AuthenticatedMutation
      description "Reply to an existing message"

      argument :input, Types::ReplyMessageInput, required: true

      field :message, Types::MessageType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        service = MessagesService.new(current_user)
        result = service.reply(
          parent_id: input[:parent_id],
          body: input[:message]
        )

        if result.success?
          { message: result.message, errors: [] }
        else
          { message: nil, errors: [result.error] }
        end
      end
    end
  end
end
