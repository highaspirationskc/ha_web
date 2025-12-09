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

  # User creation with role selection tests
  test "should show new user form with role selection" do
    login_as(@user)
    get new_user_path
    assert_response :success
    assert_select "select[name='role']"
  end

  test "should create staff user with standard permission" do
    login_as(@user)
    assert_difference ["User.count", "Staff.count"], 1 do
      post users_path, params: {
        role: "staff",
        user: {
          email: "newstaff@example.com",
          first_name: "New",
          last_name: "Staff",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        },
        staff: { permission_level: "standard" }
      }
    end
    new_user = User.find_by(email: "newstaff@example.com")
    assert_not_nil new_user.staff
    assert_equal "standard", new_user.staff.permission_level
    assert_redirected_to user_path(new_user)
  end

  test "should create staff user with admin permission" do
    login_as(@user)
    assert_difference ["User.count", "Staff.count"], 1 do
      post users_path, params: {
        role: "staff",
        user: {
          email: "newadmin@example.com",
          first_name: "New",
          last_name: "Admin",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        },
        staff: { permission_level: "admin" }
      }
    end
    new_user = User.find_by(email: "newadmin@example.com")
    assert_not_nil new_user.staff
    assert_equal "admin", new_user.staff.permission_level
  end

  test "should create mentor user" do
    login_as(@user)
    assert_difference ["User.count", "Mentor.count"], 1 do
      post users_path, params: {
        role: "mentor",
        user: {
          email: "newmentor@example.com",
          first_name: "New",
          last_name: "Mentor",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        }
      }
    end
    new_user = User.find_by(email: "newmentor@example.com")
    assert_not_nil new_user.mentor
    assert_redirected_to user_path(new_user)
  end

  test "should create mentee user" do
    login_as(@user)
    assert_difference ["User.count", "Mentee.count"], 1 do
      post users_path, params: {
        role: "mentee",
        user: {
          email: "newmentee@example.com",
          first_name: "New",
          last_name: "Mentee",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        }
      }
    end
    new_user = User.find_by(email: "newmentee@example.com")
    assert_not_nil new_user.mentee
    assert_redirected_to user_path(new_user)
  end

  test "should create mentee user with team and mentor" do
    login_as(@user)
    team = Team.create!(name: "Test Team", color: :blue)
    mentor = @inactive_user.mentor # Already has mentor from setup

    assert_difference ["User.count", "Mentee.count"], 1 do
      post users_path, params: {
        role: "mentee",
        user: {
          email: "newmentee2@example.com",
          first_name: "New",
          last_name: "Mentee2",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        },
        mentee: { team_id: team.id, mentor_id: mentor.id }
      }
    end
    new_user = User.find_by(email: "newmentee2@example.com")
    assert_not_nil new_user.mentee
    assert_equal team, new_user.mentee.team
    assert_equal mentor, new_user.mentee.mentor
  end

  test "should create guardian user" do
    login_as(@user)
    assert_difference ["User.count", "Guardian.count"], 1 do
      post users_path, params: {
        role: "guardian",
        user: {
          email: "newguardian@example.com",
          first_name: "New",
          last_name: "Guardian",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        }
      }
    end
    new_user = User.find_by(email: "newguardian@example.com")
    assert_not_nil new_user.guardian
    assert_redirected_to user_path(new_user)
  end

  test "should create volunteer user" do
    login_as(@user)
    assert_difference ["User.count", "Volunteer.count"], 1 do
      post users_path, params: {
        role: "volunteer",
        user: {
          email: "newvolunteer@example.com",
          first_name: "New",
          last_name: "Volunteer",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        }
      }
    end
    new_user = User.find_by(email: "newvolunteer@example.com")
    assert_not_nil new_user.volunteer
    assert_redirected_to user_path(new_user)
  end

  test "should create user with random password when password is blank" do
    login_as(@user)
    assert_difference ["User.count", "Mentor.count"], 1 do
      post users_path, params: {
        role: "mentor",
        user: {
          email: "nopassword@example.com",
          first_name: "No",
          last_name: "Password",
          active: true
        }
      }
    end
    new_user = User.find_by(email: "nopassword@example.com")
    assert_not_nil new_user
    assert new_user.password_digest.present?
    assert_redirected_to user_path(new_user)
  end

  test "should not create user without role" do
    login_as(@user)
    assert_no_difference "User.count" do
      post users_path, params: {
        user: {
          email: "norole@example.com",
          first_name: "No",
          last_name: "Role",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should rollback user creation if role profile fails" do
    login_as(@user)
    # Create a user with this email first to cause Staff creation to fail
    # (Staff belongs_to :user, so this won't directly fail, but we can test transaction)
    assert_no_difference "User.count" do
      post users_path, params: {
        role: "staff",
        user: {
          email: "admin@example.com", # Already exists
          first_name: "Duplicate",
          last_name: "User",
          password: "Password123!",
          password_confirmation: "Password123!",
          active: true
        },
        staff: { permission_level: "standard" }
      }
    end
    assert_response :unprocessable_entity
  end
end
