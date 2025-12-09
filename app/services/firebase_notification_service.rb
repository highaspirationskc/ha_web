require "net/http"
require "json"
require "googleauth"

class FirebaseNotificationService
  FCM_ENDPOINT = "https://fcm.googleapis.com/v1/projects/%{project_id}/messages:send".freeze
  FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging".freeze

  class NotificationError < StandardError; end

  def initialize(credentials: nil)
    @credentials = credentials || Rails.application.credentials.firebase
    raise NotificationError, "Firebase credentials not configured" unless @credentials
  end

  def send_notification(device_tokens, title:, body:, data: {})
    return [] if device_tokens.blank?

    results = device_tokens.map do |token|
      send_to_token(token, title: title, body: body, data: data)
    end

    handle_invalid_tokens(results)
    results
  end

  def send_to_user(user, title:, body:, data: {})
    tokens = user.user_devices.pluck(:fcm_token)
    send_notification(tokens, title: title, body: body, data: data)
  end

  def send_to_users(users, title:, body:, data: {})
    tokens = UserDevice.where(user: users).pluck(:fcm_token)
    send_notification(tokens, title: title, body: body, data: data)
  end

  private

  def send_to_token(token, title:, body:, data:)
    uri = URI(FCM_ENDPOINT % { project_id: @credentials[:project_id] })

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Content-Type"] = "application/json"
    request.body = build_message(token, title, body, data).to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    {
      token: token,
      success: response.code == "200",
      response_code: response.code,
      response_body: parse_response_body(response.body)
    }
  rescue StandardError => e
    {
      token: token,
      success: false,
      error: e.message
    }
  end

  def build_message(token, title, body, data)
    {
      message: {
        token: token,
        notification: {
          title: title,
          body: body
        },
        data: data.transform_values(&:to_s)
      }
    }
  end

  def access_token
    @authorizer ||= Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(service_account_json),
      scope: FCM_SCOPE
    )
    @authorizer.fetch_access_token!["access_token"]
  end

  def service_account_json
    {
      type: "service_account",
      project_id: @credentials[:project_id],
      private_key: @credentials[:private_key],
      client_email: @credentials[:client_email],
      token_uri: "https://oauth2.googleapis.com/token"
    }.to_json
  end

  def handle_invalid_tokens(results)
    invalid_tokens = results.select do |r|
      !r[:success] && invalid_token_error?(r)
    end.map { |r| r[:token] }

    UserDevice.where(fcm_token: invalid_tokens).destroy_all if invalid_tokens.any?
  end

  def invalid_token_error?(result)
    body = result[:response_body]
    return false unless body.is_a?(Hash)

    error = body["error"]
    return false unless error.is_a?(Hash)

    details = error["details"]
    return false unless details.is_a?(Array)

    details.any? do |d|
      d["errorCode"] == "UNREGISTERED" || d["errorCode"] == "INVALID_ARGUMENT"
    end
  end

  def parse_response_body(body)
    JSON.parse(body)
  rescue JSON::ParserError
    { "raw" => body }
  end
end
