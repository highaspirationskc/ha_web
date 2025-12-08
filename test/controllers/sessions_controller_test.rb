require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email: "admin@example.com",
      password: "Password123!"
    )
    Staff.create!(user: @user, permission_level: :admin)
    @user.activate!

    @staff_user = User.create!(
      email: "staff@example.com",
      password: "Password123!"
    )
    Staff.create!(user: @staff_user, permission_level: :standard)
    @staff_user.activate!

    @volunteer_user = User.create!(
      email: "volunteer@example.com",
      password: "Password123!"
    )
    Volunteer.create!(user: @volunteer_user)
    @volunteer_user.activate!
  end

  test "should get login page" do
    get login_path
    assert_response :success
  end

  test "should login with valid admin credentials" do
    post login_path, params: { email: @user.email, password: "Password123!" }
    assert_redirected_to dashboard_path
    assert_equal @user.id, session[:user_id]
    assert_equal "Logged in successfully", flash[:notice]
  end

  test "should login with valid staff credentials" do
    post login_path, params: { email: @staff_user.email, password: "Password123!" }
    assert_redirected_to dashboard_path
    assert_equal @staff_user.id, session[:user_id]
  end

  test "should not login with invalid password" do
    post login_path, params: { email: @user.email, password: "WrongPassword!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
    assert_equal "Invalid email or password", flash[:alert]
  end

  test "should not login with non-existent email" do
    post login_path, params: { email: "nonexistent@example.com", password: "Password123!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
  end

  test "should not login with non-staff role" do
    post login_path, params: { email: @volunteer_user.email, password: "Password123!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
    assert_match /don't have permission/, flash[:alert]
  end

  test "should not login with inactive user" do
    @user.deactivate!
    post login_path, params: { email: @user.email, password: "Password123!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
    assert_match /confirm your email/, flash[:alert]
  end

  test "should logout" do
    post login_path, params: { email: @user.email, password: "Password123!" }
    assert session[:user_id]

    delete logout_path
    assert_redirected_to root_path
    assert_nil session[:user_id]
    assert_equal "Logged out successfully", flash[:notice]
  end
end
