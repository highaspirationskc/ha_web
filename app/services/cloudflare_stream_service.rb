require "net/http"
require "json"

class CloudflareStreamService
  API_BASE = "https://api.cloudflare.com/client/v4/accounts".freeze

  class UploadError < StandardError; end
  class DeleteError < StandardError; end
  class ConfigurationError < StandardError; end

  class << self
    def upload(file)
      new.upload(file)
    end

    def delete(cloudflare_id)
      new.delete(cloudflare_id)
    end

    def url(cloudflare_id)
      customer_code = Rails.application.credentials.dig(:cloudflare, :stream, :customer_code) || "test_code"
      "https://customer-#{customer_code}.cloudflarestream.com/#{cloudflare_id}/watch"
    end

    def embed_url(cloudflare_id)
      customer_code = Rails.application.credentials.dig(:cloudflare, :stream, :customer_code) || "test_code"
      "https://customer-#{customer_code}.cloudflarestream.com/#{cloudflare_id}/iframe"
    end

    def thumbnail_url(cloudflare_id)
      customer_code = Rails.application.credentials.dig(:cloudflare, :stream, :customer_code) || "test_code"
      "https://customer-#{customer_code}.cloudflarestream.com/#{cloudflare_id}/thumbnails/thumbnail.jpg"
    end
  end

  def initialize(credentials: nil)
    @credentials = credentials || cloudflare_credentials
  end

  def upload(file)
    validate_credentials!

    # Cloudflare Stream uses TUS protocol for uploads, but also supports direct upload
    # We'll use the direct creator upload endpoint
    uri = URI("#{API_BASE}/#{account_id}/stream")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_token}"

    boundary = "----CloudflareStreamUpload#{SecureRandom.hex(16)}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = build_multipart_body(file, boundary)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.read_timeout = 300 # Videos can take longer to upload
      http.request(request)
    end

    handle_upload_response(response, file)
  end

  def delete(cloudflare_id)
    validate_credentials!
    uri = URI("#{API_BASE}/#{account_id}/stream/#{cloudflare_id}")

    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{api_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_delete_response(response, cloudflare_id)
  end

  def url(cloudflare_id)
    self.class.url(cloudflare_id)
  end

  def embed_url(cloudflare_id)
    self.class.embed_url(cloudflare_id)
  end

  def thumbnail_url(cloudflare_id)
    self.class.thumbnail_url(cloudflare_id)
  end

  private

  def cloudflare_credentials
    Rails.application.credentials.dig(:cloudflare, :stream)
  end

  def validate_credentials!
    raise ConfigurationError, "Cloudflare Stream credentials not configured" unless @credentials
    raise ConfigurationError, "Cloudflare account_id not configured" unless @credentials[:account_id]
    raise ConfigurationError, "Cloudflare api_token not configured" unless @credentials[:api_token]
  end

  def account_id
    @credentials[:account_id]
  end

  def api_token
    @credentials[:api_token]
  end

  def customer_code
    @credentials[:customer_code]
  end

  def build_multipart_body(file, boundary)
    body = []
    body << "--#{boundary}"
    body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{file.original_filename}\""
    body << "Content-Type: #{file.content_type}"
    body << ""
    body << file.read
    body << "--#{boundary}--"
    body.join("\r\n")
  end

  def handle_upload_response(response, file)
    body = JSON.parse(response.body)

    unless response.code == "200" && body["success"]
      errors = body["errors"]&.map { |e| e["message"] }&.join(", ") || "Unknown error"
      raise UploadError, "Failed to upload video: #{errors}"
    end

    result = body["result"]
    {
      cloudflare_id: result["uid"],
      filename: file.original_filename,
      content_type: file.content_type,
      duration: result["duration"],
      thumbnail_url: result.dig("thumbnail")
    }
  rescue JSON::ParserError => e
    raise UploadError, "Invalid response from Cloudflare: #{e.message}"
  end

  def handle_delete_response(response, cloudflare_id)
    body = JSON.parse(response.body)

    unless response.code == "200" && body["success"]
      errors = body["errors"]&.map { |e| e["message"] }&.join(", ") || "Unknown error"
      raise DeleteError, "Failed to delete video #{cloudflare_id}: #{errors}"
    end

    true
  rescue JSON::ParserError => e
    raise DeleteError, "Invalid response from Cloudflare: #{e.message}"
  end
end
