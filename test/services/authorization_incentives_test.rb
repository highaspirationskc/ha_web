require "test_helper"

class AuthorizationIncentivesTest < ActiveSupport::TestCase
  def setup
    @admin_user = User.create!(email: "auth_inc_admin@example.com", password: "Password123!")
    Staff.create!(user: @admin_user, permission_level: :admin)

    @staff_user = User.create!(email: "auth_inc_staff@example.com", password: "Password123!")
    Staff.create!(user: @staff_user)

    @mentor_user = User.create!(email: "auth_inc_mentor@example.com", password: "Password123!")
    Mentor.create!(user: @mentor_user)

    @guardian_user = User.create!(email: "auth_inc_guardian@example.com", password: "Password123!")
    Guardian.create!(user: @guardian_user)

    @mentee_user = User.create!(email: "auth_inc_mentee@example.com", password: "Password123!")
    Mentee.create!(user: @mentee_user)

    @volunteer_user = User.create!(email: "auth_inc_volunteer@example.com", password: "Password123!")
    Volunteer.create!(user: @volunteer_user)
  end

  # Admin permissions
  test "admin can index incentives" do
    assert Authorization.can?(@admin_user, :index, :incentives)
  end

  test "admin can show incentives" do
    assert Authorization.can?(@admin_user, :show, :incentives)
  end

  test "admin can create incentives" do
    assert Authorization.can?(@admin_user, :create, :incentives)
  end

  test "admin can edit incentives" do
    assert Authorization.can?(@admin_user, :edit, :incentives)
  end

  test "admin can delete incentives" do
    assert Authorization.can?(@admin_user, :delete, :incentives)
  end

  # Staff permissions
  test "staff can index incentives" do
    assert Authorization.can?(@staff_user, :index, :incentives)
  end

  test "staff can show incentives" do
    assert Authorization.can?(@staff_user, :show, :incentives)
  end

  test "staff can create incentives" do
    assert Authorization.can?(@staff_user, :create, :incentives)
  end

  test "staff can edit incentives" do
    assert Authorization.can?(@staff_user, :edit, :incentives)
  end

  test "staff can delete incentives" do
    assert Authorization.can?(@staff_user, :delete, :incentives)
  end

  # Mentor permissions (no access)
  test "mentor cannot index incentives" do
    assert_not Authorization.can?(@mentor_user, :index, :incentives)
  end

  test "mentor cannot create incentives" do
    assert_not Authorization.can?(@mentor_user, :create, :incentives)
  end

  # Guardian permissions (no access)
  test "guardian cannot index incentives" do
    assert_not Authorization.can?(@guardian_user, :index, :incentives)
  end

  test "guardian cannot create incentives" do
    assert_not Authorization.can?(@guardian_user, :create, :incentives)
  end

  # Mentee permissions (no access)
  test "mentee cannot index incentives" do
    assert_not Authorization.can?(@mentee_user, :index, :incentives)
  end

  test "mentee cannot create incentives" do
    assert_not Authorization.can?(@mentee_user, :create, :incentives)
  end

  # Volunteer permissions (no access)
  test "volunteer cannot index incentives" do
    assert_not Authorization.can?(@volunteer_user, :index, :incentives)
  end

  # Navigation access
  test "admin can access incentives navigation" do
    assert Authorization.can_access?(@admin_user, :incentives)
  end

  test "staff can access incentives navigation" do
    assert Authorization.can_access?(@staff_user, :incentives)
  end

  test "mentor cannot access incentives navigation" do
    assert_not Authorization.can_access?(@mentor_user, :incentives)
  end

  test "guardian cannot access incentives navigation" do
    assert_not Authorization.can_access?(@guardian_user, :incentives)
  end

  test "mentee cannot access incentives navigation" do
    assert_not Authorization.can_access?(@mentee_user, :incentives)
  end

  test "volunteer cannot access incentives navigation" do
    assert_not Authorization.can_access?(@volunteer_user, :incentives)
  end
end
