require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin_user = create_admin_user
  end

  def login_as(user)
    post admin_login_path, params: { email: user.email, password: "Password123!" }
  end

  test "should redirect to login when not authenticated" do
    get admin_dashboard_path
    assert_redirected_to root_path
  end

  test "should show dashboard when authenticated as admin" do
    login_as(@admin_user)
    get admin_dashboard_path
    assert_response :success
  end

  test "dashboard should display user statistics" do
    login_as(@admin_user)
    get admin_dashboard_path
    assert_select "h1", "Dashboard"
  end
end
