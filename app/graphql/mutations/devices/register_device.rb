module Mutations
  module Devices
    class RegisterDevice < AuthenticatedMutation
      description "Register a device for push notifications"

      argument :input, Types::RegisterDeviceInput, required: true

      field :device, Types::UserDeviceType, null: true
      field :errors, [String], null: false

      def resolve(input:)
        existing = UserDevice.find_by(fcm_token: input[:fcm_token])

        if existing
          if existing.user == current_user
            existing.update(
              device_name: input[:device_name],
              platform: input[:platform]
            )
            return { device: existing, errors: [] }
          else
            existing.destroy
          end
        end

        device = UserDevice.new(
          user: current_user,
          fcm_token: input[:fcm_token],
          device_name: input[:device_name],
          platform: input[:platform]
        )

        if device.save
          { device: device, errors: [] }
        else
          { device: nil, errors: device.errors.full_messages }
        end
      end
    end
  end
end
