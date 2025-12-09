module Mutations
  module Devices
    class UnregisterDevice < AuthenticatedMutation
      description "Unregister a device from push notifications"

      argument :fcm_token, String, required: true

      field :success, Boolean, null: false
      field :errors, [String], null: false

      def resolve(fcm_token:)
        device = current_user.user_devices.find_by(fcm_token: fcm_token)

        unless device
          return { success: false, errors: ["Device not found"] }
        end

        device.destroy
        { success: true, errors: [] }
      end
    end
  end
end
