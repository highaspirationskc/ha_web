# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

class SeasEvaluationMessageTest < ActiveSupport::TestCase
  def setup
    @mentee_user = User.create!(email: "seas_eval_msg_mentee@example.com", password: "Password123!", first_name: "Tina", last_name: "Mentee")
    Mentee.create!(user: @mentee_user)
    @mentee_user.activate!
    @mentee_user.reload
    @evaluation = SeasEvaluation.create!(mentee: @mentee_user.mentee, evaluation_year: 2026)
  end

  test "delivers message with correct attributes" do
    result = SeasEvaluationMessage.new(@evaluation).deliver

    assert result.success?
    message = result.message
    assert_nil message.author
    assert_equal "Your SEAS Self Evaluation is ready", message.subject
    assert_includes message.message, @mentee_user.first_name
    assert_includes message.message, @evaluation.token
    assert message.no_replies?
    assert_not message.support?
    assert_includes message.recipients, @mentee_user
  end

  test "delivers push notification with inline adapter" do
    UserDevice.create!(user: @mentee_user, fcm_token: "mentee_token", platform: "ios")
    stub_firebase_credentials
    stub_google_auth
    stub_fcm_success

    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline

    SeasEvaluationMessage.new(@evaluation).deliver

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
