require "test_helper"

class DevicesMutationsTest < ActiveSupport::TestCase
  def setup
    @user = create_user(email: "device_user@example.com")
    @other_user = create_user(email: "other_device_user@example.com")
  end

  # RegisterDevice tests

  test "can register new device" do
    mutation = <<~GQL
      mutation($input: RegisterDeviceInput!) {
        registerDevice(input: $input) {
          device {
            id
            deviceName
            platform
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        fcmToken: "new_fcm_token_123",
        deviceName: "iPhone 14",
        platform: "ios"
      }
    }, context: { current_user: @user })

    device = result.dig("data", "registerDevice", "device")
    errors = result.dig("data", "registerDevice", "errors")

    assert_not_nil device
    assert_equal "iPhone 14", device["deviceName"]
    assert_equal "ios", device["platform"]
    assert_empty errors
  end

  test "can register device without device name" do
    mutation = <<~GQL
      mutation($input: RegisterDeviceInput!) {
        registerDevice(input: $input) {
          device {
            id
            deviceName
            platform
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        fcmToken: "token_no_name",
        platform: "android"
      }
    }, context: { current_user: @user })

    device = result.dig("data", "registerDevice", "device")
    assert_not_nil device
    assert_nil device["deviceName"]
    assert_equal "android", device["platform"]
  end

  test "updates existing device for same user" do
    existing = UserDevice.create!(
      user: @user,
      fcm_token: "existing_token",
      device_name: "Old Name",
      platform: "ios"
    )

    mutation = <<~GQL
      mutation($input: RegisterDeviceInput!) {
        registerDevice(input: $input) {
          device {
            id
            deviceName
            platform
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        fcmToken: "existing_token",
        deviceName: "New Name",
        platform: "ios"
      }
    }, context: { current_user: @user })

    device = result.dig("data", "registerDevice", "device")
    assert_equal existing.id.to_s, device["id"]
    assert_equal "New Name", device["deviceName"]
  end

  test "reassigns device from another user" do
    UserDevice.create!(
      user: @other_user,
      fcm_token: "shared_token",
      platform: "ios"
    )

    mutation = <<~GQL
      mutation($input: RegisterDeviceInput!) {
        registerDevice(input: $input) {
          device {
            id
            platform
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        fcmToken: "shared_token",
        platform: "ios"
      }
    }, context: { current_user: @user })

    device = result.dig("data", "registerDevice", "device")
    errors = result.dig("data", "registerDevice", "errors")

    assert_not_nil device
    assert_empty errors
    assert_equal 1, UserDevice.where(fcm_token: "shared_token").count
    assert_equal @user.id, UserDevice.find_by(fcm_token: "shared_token").user_id
  end

  test "register device requires authentication" do
    mutation = <<~GQL
      mutation($input: RegisterDeviceInput!) {
        registerDevice(input: $input) {
          device {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        fcmToken: "token",
        platform: "ios"
      }
    }, context: {})

    assert_nil result.dig("data", "registerDevice")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  test "register device validates platform" do
    mutation = <<~GQL
      mutation($input: RegisterDeviceInput!) {
        registerDevice(input: $input) {
          device {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        fcmToken: "token",
        platform: "invalid_platform"
      }
    }, context: { current_user: @user })

    errors = result.dig("data", "registerDevice", "errors")
    assert errors.any? { |e| e.include?("Platform") }
  end

  # UnregisterDevice tests

  test "can unregister device" do
    device = UserDevice.create!(
      user: @user,
      fcm_token: "token_to_remove",
      platform: "ios"
    )

    mutation = <<~GQL
      mutation($fcmToken: String!) {
        unregisterDevice(fcmToken: $fcmToken) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      fcmToken: "token_to_remove"
    }, context: { current_user: @user })

    success = result.dig("data", "unregisterDevice", "success")
    errors = result.dig("data", "unregisterDevice", "errors")

    assert success
    assert_empty errors
    assert_nil UserDevice.find_by(id: device.id)
  end

  test "unregister device returns error if not found" do
    mutation = <<~GQL
      mutation($fcmToken: String!) {
        unregisterDevice(fcmToken: $fcmToken) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      fcmToken: "nonexistent_token"
    }, context: { current_user: @user })

    success = result.dig("data", "unregisterDevice", "success")
    errors = result.dig("data", "unregisterDevice", "errors")

    assert_not success
    assert_includes errors, "Device not found"
  end

  test "cannot unregister another user's device" do
    UserDevice.create!(
      user: @other_user,
      fcm_token: "other_user_token",
      platform: "ios"
    )

    mutation = <<~GQL
      mutation($fcmToken: String!) {
        unregisterDevice(fcmToken: $fcmToken) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      fcmToken: "other_user_token"
    }, context: { current_user: @user })

    success = result.dig("data", "unregisterDevice", "success")
    errors = result.dig("data", "unregisterDevice", "errors")

    assert_not success
    assert_includes errors, "Device not found"
  end

  test "unregister device requires authentication" do
    mutation = <<~GQL
      mutation($fcmToken: String!) {
        unregisterDevice(fcmToken: $fcmToken) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      fcmToken: "token"
    }, context: {})

    assert_nil result.dig("data", "unregisterDevice")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
