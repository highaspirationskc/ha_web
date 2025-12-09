require "test_helper"
require "webmock/minitest"

class SendPushNotificationJobTest < ActiveSupport::TestCase
  def setup
    @sender = create_user(email: "sender@example.com")
    @sender.update!(first_name: "John")
    @recipient = create_user(email: "recipient@example.com")
    @recipient.update!(first_name: "Jane")

    @device = UserDevice.create!(user: @recipient, fcm_token: "recipient_token", platform: "ios")

    @message = Message.create!(
      author: @sender,
      subject: "Test Subject",
      message: "This is a test message body",
      reply_mode: :reply_to_sender
    )
    MessageRecipient.create!(message: @message, recipient: @recipient)

    stub_firebase_credentials
    stub_google_auth
    stub_fcm_success
  end

  test "sends notification to message recipients" do
    SendPushNotificationJob.perform_now(@message.id)

    assert_requested :post, %r{fcm\.googleapis\.com}, times: 1
  end

  test "does not send notification to author" do
    UserDevice.create!(user: @sender, fcm_token: "sender_token", platform: "ios")

    SendPushNotificationJob.perform_now(@message.id)

    assert_requested :post, %r{fcm\.googleapis\.com}, times: 1
  end

  test "does nothing if message not found" do
    SendPushNotificationJob.perform_now(999999)

    assert_not_requested :post, %r{fcm\.googleapis\.com}
  end

  test "does nothing if no recipients" do
    MessageRecipient.where(message: @message).destroy_all

    SendPushNotificationJob.perform_now(@message.id)

    assert_not_requested :post, %r{fcm\.googleapis\.com}
  end

  test "does nothing if recipients have no devices" do
    UserDevice.destroy_all

    SendPushNotificationJob.perform_now(@message.id)

    assert_not_requested :post, %r{fcm\.googleapis\.com}
  end

  test "notification title includes sender name" do
    SendPushNotificationJob.perform_now(@message.id)

    assert_requested(:post, %r{fcm\.googleapis\.com}) do |req|
      body = JSON.parse(req.body)
      body.dig("message", "notification", "title").include?("John")
    end
  end

  test "notification body includes subject" do
    SendPushNotificationJob.perform_now(@message.id)

    assert_requested(:post, %r{fcm\.googleapis\.com}) do |req|
      body = JSON.parse(req.body)
      body.dig("message", "notification", "body").include?("Test Subject")
    end
  end

  test "notification data includes message_id" do
    SendPushNotificationJob.perform_now(@message.id)

    assert_requested(:post, %r{fcm\.googleapis\.com}) do |req|
      body = JSON.parse(req.body)
      body.dig("message", "data", "message_id") == @message.id.to_s
    end
  end

  test "handles firebase errors gracefully" do
    stub_request(:post, %r{fcm\.googleapis\.com})
      .to_return(status: 500, body: { error: "Server error" }.to_json)

    assert_nothing_raised do
      SendPushNotificationJob.perform_now(@message.id)
    end
  end

  test "sends notifications to multiple recipients" do
    other_recipient = create_user(email: "other@example.com")
    UserDevice.create!(user: other_recipient, fcm_token: "other_token", platform: "android")
    MessageRecipient.create!(message: @message, recipient: other_recipient)

    SendPushNotificationJob.perform_now(@message.id)

    assert_requested :post, %r{fcm\.googleapis\.com}, times: 2
  end

  private

  def stub_firebase_credentials
    credentials = {
      project_id: "test-project",
      private_key: OpenSSL::PKey::RSA.new(2048).to_pem,
      client_email: "test@test-project.iam.gserviceaccount.com"
    }
    Rails.application.credentials.stubs(:firebase).returns(credentials)
  end

  def stub_google_auth
    stub_request(:post, %r{googleapis\.com/oauth2/v4/token})
      .to_return(
        status: 200,
        body: { access_token: "mock_access_token", expires_in: 3600 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_fcm_success
    stub_request(:post, %r{fcm\.googleapis\.com})
      .to_return(
        status: 200,
        body: { name: "projects/test-project/messages/123" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
