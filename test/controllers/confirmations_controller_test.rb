require "test_helper"

class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
  end

  test "show with valid token displays password form" do
    assert_not @user.active?

    get confirmation_path(token: @user.confirmation_token)

    assert_response :success
    assert_select "input[name='password']"
    assert_select "input[name='password_confirmation']"
  end

  test "show with invalid token redirects with error" do
    get confirmation_path(token: "invalid_token")

    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link", flash[:error]
  end

  test "show with used token redirects with invalid message" do
    token = @user.confirmation_token
    @user.activate!  # This clears the token

    get confirmation_path(token: token)

    # Token was cleared, so lookup returns nil
    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link", flash[:error]
  end

  test "confirm with valid token and password activates user" do
    assert_not @user.active?

    post confirmation_path(token: @user.confirmation_token), params: {
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    @user.reload
    assert @user.active?
    assert @user.authenticate("NewPassword123!")
    assert_redirected_to root_path
    assert_equal "Your account has been confirmed! You can now log in.", flash[:success]
  end

  test "confirm with invalid token shows error" do
    post confirmation_path(token: "invalid_token"), params: {
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link", flash[:error]
  end

  test "confirm with used token redirects with invalid message" do
    token = @user.confirmation_token
    @user.activate!  # This clears the token

    post confirmation_path(token: token), params: {
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    # Token was cleared, so lookup returns nil
    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link", flash[:error]
  end

  test "confirm with blank password shows error" do
    post confirmation_path(token: @user.confirmation_token), params: {
      password: "",
      password_confirmation: ""
    }

    assert_response :unprocessable_entity
    assert_equal "Password is required", flash[:error]
  end

  test "confirm with mismatched passwords shows error" do
    post confirmation_path(token: @user.confirmation_token), params: {
      password: "NewPassword123!",
      password_confirmation: "DifferentPassword123!"
    }

    assert_response :unprocessable_entity
    @user.reload
    assert_not @user.active?
  end

  test "confirm with weak password shows error" do
    post confirmation_path(token: @user.confirmation_token), params: {
      password: "weak",
      password_confirmation: "weak"
    }

    assert_response :unprocessable_entity
    @user.reload
    assert_not @user.active?
  end

  # Token expiration tests
  test "show with expired token redirects with error" do
    @user.update!(confirmation_sent_at: 25.hours.ago)

    get confirmation_path(token: @user.confirmation_token)

    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link", flash[:error]
  end

  test "confirm with expired token shows error" do
    @user.update!(confirmation_sent_at: 25.hours.ago)

    post confirmation_path(token: @user.confirmation_token), params: {
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    assert_redirected_to root_path
    assert_equal "Invalid or expired confirmation link", flash[:error]
  end

  # Password reset for active users tests
  test "show with valid token for active user displays password form" do
    @user.activate!
    @user.request_password_reset!

    get confirmation_path(token: @user.confirmation_token)

    assert_response :success
    assert_select "input[name='password']"
  end

  test "confirm with valid token for active user updates password" do
    @user.activate!
    @user.request_password_reset!
    token = @user.confirmation_token

    post confirmation_path(token: token), params: {
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    @user.reload
    assert @user.active?
    assert @user.authenticate("NewPassword123!")
    assert_nil @user.confirmation_token
    assert_redirected_to root_path
    assert_equal "Your password has been updated! You can now log in.", flash[:success]
  end

  test "confirm clears token after successful password set" do
    token = @user.confirmation_token

    post confirmation_path(token: token), params: {
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }

    @user.reload
    assert_nil @user.confirmation_token
    assert_nil @user.confirmation_sent_at
  end
end
