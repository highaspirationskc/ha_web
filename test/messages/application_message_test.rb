# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class ApplicationMessageTest < ActiveSupport::TestCase
  # Concrete test subclass
  class TestMessage < ApplicationMessage
    attr_accessor :_subject, :_body, :_recipients, :_author, :_reply_mode, :_support

    def subject    = _subject
    def body       = _body
    def recipients = _recipients
    def author     = _author
    def reply_mode = (_reply_mode || super)
    def support?   = (_support || super)
  end

  def setup
    @recipient = create_user(email: "app_msg_recipient@example.com")
  end

  test "deliver creates message with recipients in a single transaction" do
    msg = TestMessage.new
    msg._subject = "Test Subject"
    msg._body = "Test body"
    msg._recipients = [@recipient]

    result = msg.deliver

    assert result.success?
    assert_nil result.message.author
    assert_equal "Test Subject", result.message.subject
    assert_equal "Test body", result.message.message
    assert result.message.no_replies?
    assert_not result.message.support?
    assert_includes result.message.recipients, @recipient
  end

  test "deliver sets author when provided" do
    author = create_staff_user(email: "app_msg_author@example.com")
    msg = TestMessage.new
    msg._subject = "Authored"
    msg._body = "Body"
    msg._recipients = [@recipient]
    msg._author = author

    result = msg.deliver

    assert result.success?
    assert_equal author, result.message.author
  end

  test "deliver sets reply_mode and support" do
    msg = TestMessage.new
    msg._subject = "Support"
    msg._body = "Body"
    msg._recipients = [@recipient]
    msg._reply_mode = :reply_to_all
    msg._support = true

    result = msg.deliver

    assert result.success?
    assert result.message.reply_to_all?
    assert result.message.support?
  end

  test "deliver returns error when subject is blank" do
    msg = TestMessage.new
    msg._subject = ""
    msg._body = "Body"
    msg._recipients = [@recipient]

    result = msg.deliver

    assert_not result.success?
    assert_match(/subject/i, result.error)
  end

  test "deliver returns error when body is blank" do
    msg = TestMessage.new
    msg._subject = "Subject"
    msg._body = ""
    msg._recipients = [@recipient]

    result = msg.deliver

    assert_not result.success?
    assert_match(/body/i, result.error)
  end

  test "deliver returns error when recipients is empty" do
    msg = TestMessage.new
    msg._subject = "Subject"
    msg._body = "Body"
    msg._recipients = []

    result = msg.deliver

    assert_not result.success?
    assert_match(/recipient/i, result.error)
  end

  test "deliver sends push notification to recipients" do
    UserDevice.create!(user: @recipient, fcm_token: "test_token", platform: "ios")
    stub_firebase_credentials
    stub_google_auth
    stub_fcm_success

    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline

    msg = TestMessage.new
    msg._subject = "Push Test"
    msg._body = "Body"
    msg._recipients = [@recipient]

    msg.deliver

    assert_requested :post, %r{fcm\.googleapis\.com}, times: 1
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
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
