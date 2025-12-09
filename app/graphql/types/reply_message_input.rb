module Types
  class ReplyMessageInput < Types::BaseInputObject
    description "Input for replying to a message"

    argument :parent_id, ID, required: true
    argument :message, String, required: true
  end
end
