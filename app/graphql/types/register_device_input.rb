module Types
  class RegisterDeviceInput < Types::BaseInputObject
    description "Input for registering a device for push notifications"

    argument :fcm_token, String, required: true
    argument :device_name, String, required: false
    argument :platform, String, required: true, description: "Platform: ios, android, or web"
  end
end
