require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
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

    @inactive_user = User.create!(
      email: "inactive@example.com",
      password: "Password123!",
      role: :mentor
    )
  end

  def login_as(user)
    post admin_login_path, params: { email: user.email, password: "Password123!" }
  end

  test "should redirect to login when not authenticated for index" do
    get admin_users_path
    assert_redirected_to root_path
  end

  test "should show users index when authenticated as admin" do
    login_as(@admin_user)
    get admin_users_path
    assert_response :success
    assert_select "h1", "Users"
  end

  test "should show users index when authenticated as staff" do
    login_as(@staff_user)
    get admin_users_path
    assert_response :success
  end

  test "should redirect to login when not authenticated for show" do
    get admin_user_path(@volunteer_user)
    assert_redirected_to root_path
  end

  test "should show user details when authenticated" do
    login_as(@admin_user)
    get admin_user_path(@volunteer_user)
    assert_response :success
    assert_select "h1", "User Details"
    assert_select "dd", @volunteer_user.email
  end

  test "should redirect to login when not authenticated for edit" do
    get edit_admin_user_path(@volunteer_user)
    assert_redirected_to root_path
  end

  test "should show edit form when authenticated" do
    login_as(@admin_user)
    get edit_admin_user_path(@volunteer_user)
    assert_response :success
    assert_select "h1", "Edit User"
  end

  test "should update user with valid params" do
    login_as(@admin_user)
    patch admin_user_path(@volunteer_user), params: {
      user: { email: "newemail@example.com", role: "mentor" }
    }
    assert_redirected_to admin_user_path(@volunteer_user)
    @volunteer_user.reload
    assert_equal "newemail@example.com", @volunteer_user.email
    assert_equal "mentor", @volunteer_user.role
  end

  test "should not update user with invalid email" do
    login_as(@admin_user)
    patch admin_user_path(@volunteer_user), params: {
      user: { email: "invalid-email" }
    }
    assert_response :unprocessable_entity
  end

  test "should activate inactive user" do
    login_as(@admin_user)
    assert_not @inactive_user.active?
    patch activate_admin_user_path(@inactive_user)
    assert_redirected_to admin_user_path(@inactive_user)
    @inactive_user.reload
    assert @inactive_user.active?
    assert_equal "User activated successfully", flash[:notice]
  end

  test "should deactivate active user" do
    login_as(@admin_user)
    assert @volunteer_user.active?
    patch deactivate_admin_user_path(@volunteer_user)
    assert_redirected_to admin_user_path(@volunteer_user)
    @volunteer_user.reload
    assert_not @volunteer_user.active?
    assert_equal "User deactivated successfully", flash[:notice]
  end

  test "should paginate users on index" do
    login_as(@admin_user)
    # Create 30 additional users to test pagination
    30.times do |i|
      User.create!(
        email: "user#{i}@example.com",
        password: "Password123!",
        role: :volunteer
      )
    end
    get admin_users_path
    assert_response :success
    # Kaminari default is 25 per page
    assert_select "tbody tr", count: 25
  end

  test "should update active status via checkbox" do
    login_as(@admin_user)
    patch admin_user_path(@volunteer_user), params: {
      user: { active: "0" }
    }
    assert_redirected_to admin_user_path(@volunteer_user)
    @volunteer_user.reload
    assert_not @volunteer_user.active?
  end
end
