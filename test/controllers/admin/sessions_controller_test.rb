require "test_helper"

class Admin::SessionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = User.create!(
      email: "admin@example.com",
      password: "Password123!",
      role: :admin
    )
    @admin_user.activate!

    @staff_user = User.create!(
      email: "staff@example.com",
      password: "Password123!",
      role: :staff
    )
    @staff_user.activate!

    @volunteer_user = User.create!(
      email: "volunteer@example.com",
      password: "Password123!",
      role: :volunteer
    )
    @volunteer_user.activate!
  end

  test "should get login page" do
    get admin_login_path
    assert_response :success
  end

  test "should login with valid admin credentials" do
    post admin_login_path, params: { email: @admin_user.email, password: "Password123!" }
    assert_redirected_to admin_dashboard_path
    assert_equal @admin_user.id, session[:user_id]
    assert_equal "Logged in successfully", flash[:notice]
  end

  test "should login with valid staff credentials" do
    post admin_login_path, params: { email: @staff_user.email, password: "Password123!" }
    assert_redirected_to admin_dashboard_path
    assert_equal @staff_user.id, session[:user_id]
  end

  test "should not login with invalid password" do
    post admin_login_path, params: { email: @admin_user.email, password: "WrongPassword!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
    assert_equal "Invalid email or password", flash[:alert]
  end

  test "should not login with non-existent email" do
    post admin_login_path, params: { email: "nonexistent@example.com", password: "Password123!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
  end

  test "should not login with non-admin/staff role" do
    post admin_login_path, params: { email: @volunteer_user.email, password: "Password123!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
    assert_match /don't have permission/, flash[:alert]
  end

  test "should not login with inactive user" do
    @admin_user.deactivate!
    post admin_login_path, params: { email: @admin_user.email, password: "Password123!" }
    assert_response :unauthorized
    assert_nil session[:user_id]
    assert_match /confirm your email/, flash[:alert]
  end

  test "should logout" do
    post admin_login_path, params: { email: @admin_user.email, password: "Password123!" }
    assert session[:user_id]

    delete admin_logout_path
    assert_redirected_to root_path
    assert_nil session[:user_id]
    assert_equal "Logged out successfully", flash[:notice]
  end
end
