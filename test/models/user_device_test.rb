require "test_helper"

class UserDeviceTest < ActiveSupport::TestCase
  def setup
    @user = create_user(email: "device_test@example.com")
  end

  test "valid user device" do
    device = UserDevice.new(
      user: @user,
      fcm_token: "test_fcm_token_123",
      platform: "ios",
      device_name: "iPhone 14"
    )
    assert device.valid?
  end

  test "requires user" do
    device = UserDevice.new(
      fcm_token: "test_fcm_token_123",
      platform: "ios"
    )
    assert_not device.valid?
    assert_includes device.errors[:user], "must exist"
  end

  test "requires fcm_token" do
    device = UserDevice.new(
      user: @user,
      platform: "ios"
    )
    assert_not device.valid?
    assert_includes device.errors[:fcm_token], "can't be blank"
  end

  test "requires platform" do
    device = UserDevice.new(
      user: @user,
      fcm_token: "test_fcm_token_123"
    )
    assert_not device.valid?
    assert_includes device.errors[:platform], "can't be blank"
  end

  test "fcm_token must be unique" do
    UserDevice.create!(
      user: @user,
      fcm_token: "unique_token_123",
      platform: "ios"
    )

    other_user = create_user(email: "other@example.com")
    duplicate = UserDevice.new(
      user: other_user,
      fcm_token: "unique_token_123",
      platform: "android"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:fcm_token], "has already been taken"
  end

  test "platform must be ios, android, or web" do
    device = UserDevice.new(
      user: @user,
      fcm_token: "test_token",
      platform: "invalid"
    )
    assert_not device.valid?
    assert_includes device.errors[:platform], "is not included in the list"
  end

  test "accepts ios platform" do
    device = UserDevice.new(user: @user, fcm_token: "token1", platform: "ios")
    assert device.valid?
  end

  test "accepts android platform" do
    device = UserDevice.new(user: @user, fcm_token: "token2", platform: "android")
    assert device.valid?
  end

  test "accepts web platform" do
    device = UserDevice.new(user: @user, fcm_token: "token3", platform: "web")
    assert device.valid?
  end

  test "device_name is optional" do
    device = UserDevice.new(
      user: @user,
      fcm_token: "test_token_no_name",
      platform: "ios"
    )
    assert device.valid?
    assert_nil device.device_name
  end

  test "for_platform scope filters by platform" do
    UserDevice.create!(user: @user, fcm_token: "ios_token", platform: "ios")
    UserDevice.create!(user: @user, fcm_token: "android_token", platform: "android")
    UserDevice.create!(user: @user, fcm_token: "web_token", platform: "web")

    assert_equal 1, UserDevice.for_platform("ios").count
    assert_equal 1, UserDevice.for_platform("android").count
    assert_equal 1, UserDevice.for_platform("web").count
  end

  test "user has_many user_devices" do
    device1 = UserDevice.create!(user: @user, fcm_token: "token_a", platform: "ios")
    device2 = UserDevice.create!(user: @user, fcm_token: "token_b", platform: "android")

    assert_includes @user.user_devices, device1
    assert_includes @user.user_devices, device2
    assert_equal 2, @user.user_devices.count
  end

  test "destroying user destroys associated devices" do
    UserDevice.create!(user: @user, fcm_token: "token_to_destroy", platform: "ios")
    assert_difference "UserDevice.count", -1 do
      @user.destroy
    end
  end
end
