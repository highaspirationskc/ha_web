module Types
  class CheckInInput < Types::BaseInputObject
    description "Input for checking in to an event"

    argument :event_id, ID, required: true
  end
end
