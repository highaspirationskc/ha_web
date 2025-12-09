module Types
  class ComposeMessageInput < Types::BaseInputObject
    description "Input for composing a new message"

    argument :subject, String, required: true
    argument :message, String, required: true
    argument :recipient_ids, [ID], required: true
    argument :reply_mode, String, required: false, default_value: "reply_to_sender"
    argument :support, Boolean, required: false, default_value: false
  end
end
