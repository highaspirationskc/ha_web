require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
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

    @inactive_user = User.create!(
      email: "inactive@example.com",
      password: "Password123!"
    )
    Mentor.create!(user: @inactive_user)
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  test "should redirect to login when not authenticated for index" do
    get users_path
    assert_redirected_to root_path
  end

  test "should show users index when authenticated as admin" do
    login_as(@user)
    get users_path
    assert_response :success
    assert_select "h1", "Users"
  end

  test "should show users index when authenticated as staff" do
    login_as(@staff_user)
    get users_path
    assert_response :success
  end

  test "should redirect to login when not authenticated for show" do
    get user_path(@volunteer_user)
    assert_redirected_to root_path
  end

  test "should show user details when authenticated" do
    login_as(@user)
    get user_path(@volunteer_user)
    assert_response :success
    assert_select "nav[aria-label='Breadcrumb']"
    assert_select "dd", @volunteer_user.email
  end

  test "should redirect to login when not authenticated for edit" do
    get edit_user_path(@volunteer_user)
    assert_redirected_to root_path
  end

  test "should show edit form when authenticated" do
    login_as(@user)
    get edit_user_path(@volunteer_user)
    assert_response :success
    assert_select "nav[aria-label='Breadcrumb']"
  end

  test "should update user with valid params" do
    login_as(@user)
    patch user_path(@volunteer_user), params: {
      user: { email: "newemail@example.com" }
    }
    assert_redirected_to user_path(@volunteer_user)
    @volunteer_user.reload
    assert_equal "newemail@example.com", @volunteer_user.email
  end

  test "should not update user with invalid email" do
    login_as(@user)
    patch user_path(@volunteer_user), params: {
      user: { email: "invalid-email" }
    }
    assert_response :unprocessable_entity
  end

  test "should activate inactive user" do
    login_as(@user)
    assert_not @inactive_user.active?
    patch activate_user_path(@inactive_user)
    assert_redirected_to user_path(@inactive_user)
    @inactive_user.reload
    assert @inactive_user.active?
    assert_equal "User activated successfully", flash[:notice]
  end

  test "should deactivate active user" do
    login_as(@user)
    assert @volunteer_user.active?
    patch deactivate_user_path(@volunteer_user)
    assert_redirected_to user_path(@volunteer_user)
    @volunteer_user.reload
    assert_not @volunteer_user.active?
    assert_equal "User deactivated successfully", flash[:notice]
  end

  test "should paginate users on index" do
    login_as(@user)
    # Create 30 additional users to test pagination
    30.times do |i|
      User.create!(
        email: "user#{i}@example.com",
        password: "Password123!"
      )
    end
    get users_path
    assert_response :success
    # Kaminari default is 15 per page
    assert_select "tbody tr", count: 15
  end

  test "should update active status via checkbox" do
    login_as(@user)
    patch user_path(@volunteer_user), params: {
      user: { active: "0" }
    }
    assert_redirected_to user_path(@volunteer_user)
    @volunteer_user.reload
    assert_not @volunteer_user.active?
  end
end
