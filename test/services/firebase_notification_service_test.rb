require "test_helper"
require "webmock/minitest"

class FirebaseNotificationServiceTest < ActiveSupport::TestCase
  def setup
    @credentials = {
      project_id: "test-project",
      private_key: OpenSSL::PKey::RSA.new(2048).to_pem,
      client_email: "test@test-project.iam.gserviceaccount.com"
    }
    @user = create_user(email: "firebase_test@example.com")
    @device = UserDevice.create!(user: @user, fcm_token: "test_token_123", platform: "ios")

    stub_google_auth
  end

  test "raises error when credentials not configured" do
    Rails.application.credentials.stubs(:firebase).returns(nil)
    assert_raises(FirebaseNotificationService::NotificationError) do
      FirebaseNotificationService.new(credentials: nil)
    end
  end

  test "send_notification returns empty array for empty tokens" do
    service = FirebaseNotificationService.new(credentials: @credentials)
    result = service.send_notification([], title: "Test", body: "Test body")
    assert_equal [], result
  end

  test "send_notification sends to each token" do
    stub_fcm_success

    service = FirebaseNotificationService.new(credentials: @credentials)
    results = service.send_notification(
      ["token1", "token2"],
      title: "Test Title",
      body: "Test Body",
      data: { message_id: "123" }
    )

    assert_equal 2, results.length
    assert results.all? { |r| r[:success] }
  end

  test "send_to_user sends to all user devices" do
    UserDevice.create!(user: @user, fcm_token: "second_token", platform: "android")
    stub_fcm_success

    service = FirebaseNotificationService.new(credentials: @credentials)
    results = service.send_to_user(@user, title: "Test", body: "Body")

    assert_equal 2, results.length
  end

  test "send_to_users sends to multiple users" do
    other_user = create_user(email: "other_firebase@example.com")
    UserDevice.create!(user: other_user, fcm_token: "other_token", platform: "ios")
    stub_fcm_success

    service = FirebaseNotificationService.new(credentials: @credentials)
    results = service.send_to_users([@user, other_user], title: "Test", body: "Body")

    assert_equal 2, results.length
  end

  test "handles failed notifications" do
    stub_fcm_failure

    service = FirebaseNotificationService.new(credentials: @credentials)
    results = service.send_notification(["bad_token"], title: "Test", body: "Body")

    assert_equal 1, results.length
    assert_not results.first[:success]
  end

  test "removes invalid tokens from database" do
    stub_fcm_unregistered_token

    service = FirebaseNotificationService.new(credentials: @credentials)
    service.send_notification([@device.fcm_token], title: "Test", body: "Body")

    assert_nil UserDevice.find_by(fcm_token: @device.fcm_token)
  end

  test "keeps valid tokens in database after successful send" do
    stub_fcm_success

    service = FirebaseNotificationService.new(credentials: @credentials)
    service.send_notification([@device.fcm_token], title: "Test", body: "Body")

    assert UserDevice.exists?(fcm_token: @device.fcm_token)
  end

  test "data values are converted to strings" do
    stub_fcm_success

    service = FirebaseNotificationService.new(credentials: @credentials)
    results = service.send_notification(
      ["token"],
      title: "Test",
      body: "Body",
      data: { id: 123, active: true }
    )

    assert results.first[:success]
  end

  private

  def stub_google_auth
    stub_request(:post, %r{googleapis\.com/oauth2/v4/token})
      .to_return(
        status: 200,
        body: { access_token: "mock_access_token", expires_in: 3600 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_fcm_success
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/test-project/messages:send")
      .to_return(
        status: 200,
        body: { name: "projects/test-project/messages/123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_fcm_failure
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/test-project/messages:send")
      .to_return(
        status: 400,
        body: { error: { message: "Invalid token" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_fcm_unregistered_token
    stub_request(:post, "https://fcm.googleapis.com/v1/projects/test-project/messages:send")
      .to_return(
        status: 404,
        body: {
          error: {
            message: "Token not registered",
            details: [{ "errorCode" => "UNREGISTERED" }]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
