module Types
  class RegisterInput < Types::BaseInputObject
    description "Input for registering for an event"

    argument :event_id, ID, required: true
  end
end
