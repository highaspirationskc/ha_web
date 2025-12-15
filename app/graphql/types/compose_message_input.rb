module Types
  class ComposeMessageInput < Types::BaseInputObject
    description "Input for composing a new message. recipient_ids can include user IDs or group identifiers (group:everyone, group:staff, group:mentors, group:mentees, group:guardians, group:team:N, or 'support')"

    argument :subject, String, required: true
    argument :message, String, required: true
    argument :recipient_ids, [String], required: true, description: "User IDs or group identifiers"
    argument :reply_mode, String, required: false, default_value: "reply_to_sender"
    argument :support, Boolean, required: false, default_value: false
  end
end
