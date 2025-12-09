require "test_helper"
require "webmock/minitest"

class MediaControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      email: "admin_media@example.com",
      password: "Password123!"
    )
    Staff.create!(user: @admin, permission_level: :admin)
    @admin.activate!

    @staff = User.create!(
      email: "staff_media@example.com",
      password: "Password123!"
    )
    Staff.create!(user: @staff, permission_level: :standard)
    @staff.activate!

    @medium = create_medium(@admin)

    # Stub Cloudflare credentials for tests
    @test_credentials = {
      account_id: "test_account_id",
      api_token: "test_api_token",
      account_hash: "test_account_hash"
    }
    Rails.application.credentials.stubs(:dig).with(:cloudflare, :images).returns(@test_credentials)
    Rails.application.credentials.stubs(:dig).with(:cloudflare, :images, :account_hash).returns("test_account_hash")
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  test "index requires authentication" do
    get media_url
    assert_redirected_to root_path
  end

  test "admin can view index" do
    login_as @admin
    get media_url
    assert_response :success
  end

  test "staff can view index" do
    login_as @staff
    get media_url
    assert_response :success
  end

  test "show requires authentication" do
    get medium_url(@medium)
    assert_redirected_to root_path
  end

  test "admin can view show" do
    login_as @admin
    get medium_url(@medium)
    assert_response :success
  end

  test "create requires authentication" do
    post media_url, params: { file: fixture_file_upload("test_image.jpg", "image/jpeg") }
    assert_redirected_to root_path
  end

  test "admin can create medium" do
    login_as @admin
    stub_cloudflare_upload

    assert_difference("Medium.count", 1) do
      post media_url, params: {
        file: fixture_file_upload("test_image.jpg", "image/jpeg"),
        alt_text: "Test alt text"
      }
    end

    assert_redirected_to media_url
  end

  test "create returns json with medium data" do
    login_as @admin
    stub_cloudflare_upload

    assert_difference("Medium.count", 1) do
      post media_url,
        params: { file: fixture_file_upload("test_image.jpg", "image/jpeg") },
        headers: { "Accept" => "application/json" }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["id"].present?
    assert json["url"].present?
    assert json["filename"].present?
  end

  test "destroy requires authentication" do
    delete medium_url(@medium)
    assert_redirected_to root_path
  end

  test "admin can delete unused medium" do
    login_as @admin
    stub_cloudflare_delete

    assert_difference("Medium.count", -1) do
      delete medium_url(@medium)
    end

    assert_redirected_to media_url
  end

  test "cannot delete medium in use" do
    login_as @admin
    event_type = EventType.create!(name: "TestMediaType", category: "org", point_value: 10)
    Event.create!(
      name: "Test Event",
      event_date: Time.current,
      event_type: event_type,
      created_by: @admin,
      image: @medium
    )

    assert_no_difference("Medium.count") do
      delete medium_url(@medium)
    end

    assert_redirected_to medium_url(@medium)
    assert_match /in use/, flash[:alert]
  end

  test "picker requires authentication" do
    get picker_media_url
    assert_redirected_to root_path
  end

  test "admin can access picker" do
    login_as @admin
    get picker_media_url
    assert_response :success
  end

  # Token-based API authentication tests (for Flutter)
  test "create via API with bearer token" do
    token = AuthService.generate_token(@admin)
    stub_cloudflare_upload

    assert_difference("Medium.count", 1) do
      post media_url,
        params: { file: fixture_file_upload("test_image.jpg", "image/jpeg"), category: "avatar" },
        headers: {
          "Authorization" => "Bearer #{token}",
          "Accept" => "application/json"
        }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["id"].present?
    assert json["url"].present?

    medium = Medium.find(json["id"])
    assert_equal "avatar", medium.category
    assert_equal @admin, medium.uploaded_by
  end

  test "create via API without token returns unauthorized" do
    post media_url,
      params: { file: fixture_file_upload("test_image.jpg", "image/jpeg") },
      headers: { "Accept" => "application/json" }

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "Unauthorized", json["error"]
  end

  test "create via API with invalid token returns unauthorized" do
    post media_url,
      params: { file: fixture_file_upload("test_image.jpg", "image/jpeg") },
      headers: {
        "Authorization" => "Bearer invalid_token",
        "Accept" => "application/json"
      }

    assert_response :unauthorized
  end

  private

  def create_medium(user)
    Medium.create!(
      uploaded_by: user,
      cloudflare_id: "test_cf_id_#{SecureRandom.hex(8)}",
      filename: "test.jpg",
      media_type: "image",
      content_type: "image/jpeg"
    )
  end

  def stub_cloudflare_upload
    stub_request(:post, %r{api\.cloudflare\.com/client/v4/accounts/.*/images/v1})
      .to_return(
        status: 200,
        body: {
          success: true,
          result: {
            id: "cf_uploaded_id_#{SecureRandom.hex(8)}",
            filename: "test_image.jpg",
            meta: { width: 800, height: 600 },
            variants: ["https://imagedelivery.net/hash/id/public"]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_cloudflare_delete
    stub_request(:delete, %r{api\.cloudflare\.com/client/v4/accounts/.*/images/v1/.*})
      .to_return(
        status: 200,
        body: { success: true }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
