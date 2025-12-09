require "test_helper"
require "webmock/minitest"

class CloudflareImagesServiceTest < ActiveSupport::TestCase
  def setup
    @credentials = {
      account_id: "test_account_id",
      api_token: "test_api_token",
      account_hash: "test_account_hash"
    }
    @service = CloudflareImagesService.new(credentials: @credentials)
  end

  test "raises error when credentials not configured" do
    Rails.application.credentials.stubs(:dig).with(:cloudflare, :images).returns(nil)
    assert_raises(CloudflareImagesService::ConfigurationError) do
      CloudflareImagesService.new(credentials: nil)
    end
  end

  test "raises error when account_id missing" do
    assert_raises(CloudflareImagesService::ConfigurationError) do
      CloudflareImagesService.new(credentials: { api_token: "x", account_hash: "y" })
    end
  end

  test "raises error when api_token missing" do
    assert_raises(CloudflareImagesService::ConfigurationError) do
      CloudflareImagesService.new(credentials: { account_id: "x", account_hash: "y" })
    end
  end

  test "raises error when account_hash missing" do
    assert_raises(CloudflareImagesService::ConfigurationError) do
      CloudflareImagesService.new(credentials: { account_id: "x", api_token: "y" })
    end
  end

  test "generates correct image url" do
    url = @service.url("image123", variant: "public")
    assert_equal "https://imagedelivery.net/test_account_hash/image123/public", url
  end

  test "generates thumbnail url" do
    url = @service.url("image123", variant: "thumbnail")
    assert_equal "https://imagedelivery.net/test_account_hash/image123/thumbnail", url
  end

  test "upload sends file to cloudflare" do
    stub_cloudflare_upload_success

    file = mock_uploaded_file("test.jpg", "image/jpeg", "fake image content")
    result = @service.upload(file)

    assert_equal "cf_image_id_123", result[:cloudflare_id]
    assert_equal "test.jpg", result[:filename]
    assert_equal "image/jpeg", result[:content_type]
  end

  test "upload raises error on failure" do
    stub_cloudflare_upload_failure

    file = mock_uploaded_file("test.jpg", "image/jpeg", "fake image content")

    assert_raises(CloudflareImagesService::UploadError) do
      @service.upload(file)
    end
  end

  test "delete sends request to cloudflare" do
    stub_cloudflare_delete_success

    result = @service.delete("cf_image_id_123")
    assert result
  end

  test "delete raises error on failure" do
    stub_cloudflare_delete_failure

    assert_raises(CloudflareImagesService::DeleteError) do
      @service.delete("cf_image_id_123")
    end
  end

  test "class method upload delegates to instance" do
    Rails.application.credentials.stubs(:dig).with(:cloudflare, :images).returns(@credentials)
    stub_cloudflare_upload_success

    file = mock_uploaded_file("test.jpg", "image/jpeg", "content")
    result = CloudflareImagesService.upload(file)

    assert_equal "cf_image_id_123", result[:cloudflare_id]
  end

  test "class method url generates correct url" do
    Rails.application.credentials.stubs(:dig).with(:cloudflare, :images).returns(@credentials)
    url = CloudflareImagesService.url("image123", variant: "public")
    assert_includes url, "image123"
    assert_includes url, "public"
  end

  private

  def mock_uploaded_file(filename, content_type, content)
    file = Object.new
    file.define_singleton_method(:original_filename) { filename }
    file.define_singleton_method(:content_type) { content_type }
    file.define_singleton_method(:read) { content }
    file
  end

  def stub_cloudflare_upload_success
    stub_request(:post, "https://api.cloudflare.com/client/v4/accounts/test_account_id/images/v1")
      .to_return(
        status: 200,
        body: {
          success: true,
          result: {
            id: "cf_image_id_123",
            filename: "test.jpg",
            meta: { width: 800, height: 600 },
            variants: ["https://imagedelivery.net/hash/cf_image_id_123/public"]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_cloudflare_upload_failure
    stub_request(:post, "https://api.cloudflare.com/client/v4/accounts/test_account_id/images/v1")
      .to_return(
        status: 400,
        body: {
          success: false,
          errors: [{ message: "Invalid image format" }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_cloudflare_delete_success
    stub_request(:delete, "https://api.cloudflare.com/client/v4/accounts/test_account_id/images/v1/cf_image_id_123")
      .to_return(
        status: 200,
        body: { success: true }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_cloudflare_delete_failure
    stub_request(:delete, "https://api.cloudflare.com/client/v4/accounts/test_account_id/images/v1/cf_image_id_123")
      .to_return(
        status: 404,
        body: {
          success: false,
          errors: [{ message: "Image not found" }]
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
