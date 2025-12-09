require "net/http"
require "json"

class CloudflareImagesService
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

    def url(cloudflare_id, variant: "public")
      hash = Rails.application.credentials.dig(:cloudflare, :images, :account_hash) || "test_hash"
      "https://imagedelivery.net/#{hash}/#{cloudflare_id}/#{variant}"
    end
  end

  def initialize(credentials: nil)
    @credentials = credentials || cloudflare_credentials
    validate_credentials!
  end

  def upload(file)
    uri = URI("#{API_BASE}/#{account_id}/images/v1")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_token}"

    boundary = "----CloudflareUpload#{SecureRandom.hex(16)}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = build_multipart_body(file, boundary)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_upload_response(response, file)
  end

  def delete(cloudflare_id)
    uri = URI("#{API_BASE}/#{account_id}/images/v1/#{cloudflare_id}")

    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{api_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    handle_delete_response(response, cloudflare_id)
  end

  def url(cloudflare_id, variant: "public")
    "https://imagedelivery.net/#{account_hash}/#{cloudflare_id}/#{variant}"
  end

  private

  def cloudflare_credentials
    Rails.application.credentials.dig(:cloudflare, :images)
  end

  def validate_credentials!
    raise ConfigurationError, "Cloudflare Images credentials not configured" unless @credentials
    raise ConfigurationError, "Cloudflare account_id not configured" unless @credentials[:account_id]
    raise ConfigurationError, "Cloudflare api_token not configured" unless @credentials[:api_token]
    raise ConfigurationError, "Cloudflare account_hash not configured" unless @credentials[:account_hash]
  end

  def account_id
    @credentials[:account_id]
  end

  def api_token
    @credentials[:api_token]
  end

  def account_hash
    @credentials[:account_hash]
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
      raise UploadError, "Failed to upload image: #{errors}"
    end

    result = body["result"]
    {
      cloudflare_id: result["id"],
      filename: file.original_filename,
      content_type: file.content_type,
      width: result.dig("meta", "width"),
      height: result.dig("meta", "height"),
      variants: result["variants"]
    }
  rescue JSON::ParserError => e
    raise UploadError, "Invalid response from Cloudflare: #{e.message}"
  end

  def handle_delete_response(response, cloudflare_id)
    body = JSON.parse(response.body)

    unless response.code == "200" && body["success"]
      errors = body["errors"]&.map { |e| e["message"] }&.join(", ") || "Unknown error"
      raise DeleteError, "Failed to delete image #{cloudflare_id}: #{errors}"
    end

    true
  rescue JSON::ParserError => e
    raise DeleteError, "Invalid response from Cloudflare: #{e.message}"
  end
end
