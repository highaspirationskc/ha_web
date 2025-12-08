require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create_user
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  test "should redirect to login when not authenticated" do
    get dashboard_path
    assert_redirected_to root_path
  end

  test "should show dashboard when authenticated as admin" do
    login_as(@user)
    get dashboard_path
    assert_response :success
  end

  test "dashboard should display user statistics" do
    login_as(@user)
    get dashboard_path
    assert_select "h1", "Dashboard"
  end
end
