require "test_helper"

class ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
  end

  test "confirm with valid token activates user" do
    assert_not @user.active?

    get confirmation_path(token: @user.confirmation_token)

    @user.reload
    assert @user.active?
    assert_redirected_to root_path
    assert_equal "Your account has been confirmed! You can now log in.", flash[:success]
  end

  test "confirm with invalid token shows error" do
    get confirmation_path(token: "invalid_token")

    assert_redirected_to root_path
    assert_equal "Invalid confirmation token", flash[:error]
  end

  test "confirm with already active user shows error for invalid token" do
    token = @user.confirmation_token
    @user.activate!

    # After activation, token is cleared, so it will be invalid
    get confirmation_path(token: token)

    assert_redirected_to root_path
    assert_equal "Invalid confirmation token", flash[:error]
  end

  test "confirm clears confirmation token" do
    token = @user.confirmation_token

    get confirmation_path(token: token)

    @user.reload
    assert_nil @user.confirmation_token
    assert_nil @user.confirmation_sent_at
  end
end
