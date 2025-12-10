require "test_helper"

class AuthorizationTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "admin@example.com", password: "Password123!")
    Staff.create!(user: @user, permission_level: :admin)

    @staff_user = User.create!(email: "staff@example.com", password: "Password123!")
    Staff.create!(user: @staff_user)

    @mentor_user = User.create!(email: "mentor@example.com", password: "Password123!")
    Mentor.create!(user: @mentor_user)

    @guardian_user = User.create!(email: "guardian@example.com", password: "Password123!")
    Guardian.create!(user: @guardian_user)

    @mentee_user = User.create!(email: "mentee@example.com", password: "Password123!")
    Mentee.create!(user: @mentee_user)

    @volunteer_user = User.create!(email: "volunteer@example.com", password: "Password123!")
    Volunteer.create!(user: @volunteer_user)

    @other_user = User.create!(email: "other@example.com", password: "Password123!")
  end

  # Role detection
  test "determines admin role correctly" do
    assert_equal :admin, Authorization.new(@user).role
  end

  test "determines staff role correctly" do
    assert_equal :staff, Authorization.new(@staff_user).role
  end

  test "determines mentor role correctly" do
    assert_equal :mentor, Authorization.new(@mentor_user).role
  end

  test "determines guardian role correctly" do
    assert_equal :guardian, Authorization.new(@guardian_user).role
  end

  test "determines mentee role correctly" do
    assert_equal :mentee, Authorization.new(@mentee_user).role
  end

  test "determines volunteer role correctly" do
    assert_equal :volunteer, Authorization.new(@volunteer_user).role
  end

  # Admin permissions
  test "admin can delete users" do
    assert Authorization.can?(@user, :delete, :users, @other_user)
  end

  test "admin cannot delete themselves" do
    assert_not Authorization.can?(@user, :delete, :users, @user)
  end

  test "admin can change user status" do
    assert Authorization.can?(@user, :change_status, :users, @other_user)
  end

  test "admin cannot change their own status" do
    assert_not Authorization.can?(@user, :change_status, :users, @user)
  end

  test "admin can manage family members" do
    assert Authorization.can?(@user, :manage_family_members, :users)
  end

  test "admin can manage mentees" do
    assert Authorization.can?(@user, :manage_mentees, :users)
  end

  # Staff permissions
  test "staff cannot delete users" do
    assert_not Authorization.can?(@staff_user, :delete, :users, @other_user)
  end

  test "staff cannot change user status" do
    assert_not Authorization.can?(@staff_user, :change_status, :users, @other_user)
  end

  test "staff can create users" do
    assert Authorization.can?(@staff_user, :create, :users)
  end

  test "staff can edit users" do
    assert Authorization.can?(@staff_user, :edit, :users)
  end

  test "staff can manage family members" do
    assert Authorization.can?(@staff_user, :manage_family_members, :users)
  end

  test "staff can manage mentees" do
    assert Authorization.can?(@staff_user, :manage_mentees, :users)
  end

  # Mentor permissions
  test "mentor can view users" do
    assert Authorization.can?(@mentor_user, :show, :users)
  end

  test "mentor cannot create users" do
    assert_not Authorization.can?(@mentor_user, :create, :users)
  end

  test "mentor cannot edit users" do
    assert_not Authorization.can?(@mentor_user, :edit, :users)
  end

  test "mentor cannot manage family members" do
    assert_not Authorization.can?(@mentor_user, :manage_family_members, :users)
  end

  test "mentor cannot manage mentees" do
    assert_not Authorization.can?(@mentor_user, :manage_mentees, :users)
  end

  # Guardian permissions
  test "guardian cannot view users" do
    assert_not Authorization.can?(@guardian_user, :show, :users)
  end

  test "guardian cannot create users" do
    assert_not Authorization.can?(@guardian_user, :create, :users)
  end

  test "guardian cannot manage family members" do
    assert_not Authorization.can?(@guardian_user, :manage_family_members, :users)
  end

  # Mentee permissions
  test "mentee cannot view users" do
    assert_not Authorization.can?(@mentee_user, :show, :users)
  end

  test "mentee cannot create users" do
    assert_not Authorization.can?(@mentee_user, :create, :users)
  end

  # Volunteer permissions
  test "volunteer cannot view users" do
    assert_not Authorization.can?(@volunteer_user, :show, :users)
  end

  test "volunteer cannot create users" do
    assert_not Authorization.can?(@volunteer_user, :create, :users)
  end

  # Navigation
  test "admin has full navigation" do
    nav = Authorization.navigation_for(@user)
    assert_includes nav, :dashboard
    assert_includes nav, :users
    assert_includes nav, :events
    assert_includes nav, :settings
    # Settings sub-items are accessible via can_access?
    assert Authorization.can_access?(@user, :teams)
    assert Authorization.can_access?(@user, :event_types)
    assert Authorization.can_access?(@user, :olympic_seasons)
    assert Authorization.can_access?(@user, :media)
  end

  test "mentor has limited navigation" do
    nav = Authorization.navigation_for(@mentor_user)
    assert_includes nav, :dashboard
    assert_includes nav, :events
    assert_includes nav, :users
    assert_not_includes nav, :teams
  end

  test "mentee has minimal navigation" do
    nav = Authorization.navigation_for(@mentee_user)
    assert_includes nav, :dashboard
    assert_includes nav, :events
    assert_not_includes nav, :users
  end

  # User#can? helper
  test "user can? delegates to Authorization" do
    assert @user.can?(:delete, :users, @other_user)
    assert_not @staff_user.can?(:delete, :users, @other_user)
  end

  # User#allowed_navigation helper
  test "user allowed_navigation delegates to Authorization" do
    assert_includes @user.allowed_navigation, :dashboard
    assert_includes @mentee_user.allowed_navigation, :dashboard
  end

  # Edge cases
  test "nil user returns false for all permissions" do
    assert_not Authorization.can?(nil, :delete, :users, @other_user)
    assert_not Authorization.can?(nil, :show, :users)
  end

  test "nil user returns empty navigation" do
    assert_empty Authorization.navigation_for(nil)
  end

  test "user without role returns nil role" do
    assert_nil Authorization.new(@other_user).role
  end

  test "user without role cannot perform any action" do
    assert_not Authorization.can?(@other_user, :index, :users)
    assert_not Authorization.can?(@other_user, :show, :users)
    assert_not Authorization.can?(@other_user, :create, :users)
  end

  test "invalid action returns false" do
    assert_not Authorization.can?(@user, :nonexistent_action, :users)
  end

  test "invalid resource returns false" do
    assert_not Authorization.can?(@user, :show, :nonexistent_resource)
  end

  # Admin comprehensive permissions
  test "admin can index users" do
    assert Authorization.can?(@user, :index, :users)
  end

  test "admin can show users" do
    assert Authorization.can?(@user, :show, :users)
  end

  test "admin can create users" do
    assert Authorization.can?(@user, :create, :users)
  end

  test "admin can edit users" do
    assert Authorization.can?(@user, :edit, :users)
  end

  # Staff comprehensive permissions
  test "staff can index users" do
    assert Authorization.can?(@staff_user, :index, :users)
  end

  test "staff can show users" do
    assert Authorization.can?(@staff_user, :show, :users)
  end

  # Mentor comprehensive permissions
  test "mentor cannot index users" do
    assert_not Authorization.can?(@mentor_user, :index, :users)
  end

  test "mentor cannot delete users" do
    assert_not Authorization.can?(@mentor_user, :delete, :users, @other_user)
  end

  test "mentor cannot change user status" do
    assert_not Authorization.can?(@mentor_user, :change_status, :users, @other_user)
  end

  # Guardian comprehensive permissions
  test "guardian cannot index users" do
    assert_not Authorization.can?(@guardian_user, :index, :users)
  end

  test "guardian cannot edit users" do
    assert_not Authorization.can?(@guardian_user, :edit, :users)
  end

  test "guardian cannot delete users" do
    assert_not Authorization.can?(@guardian_user, :delete, :users, @other_user)
  end

  test "guardian cannot manage mentees" do
    assert_not Authorization.can?(@guardian_user, :manage_mentees, :users)
  end

  # Mentee comprehensive permissions
  test "mentee cannot index users" do
    assert_not Authorization.can?(@mentee_user, :index, :users)
  end

  test "mentee cannot edit users" do
    assert_not Authorization.can?(@mentee_user, :edit, :users)
  end

  test "mentee cannot delete users" do
    assert_not Authorization.can?(@mentee_user, :delete, :users, @other_user)
  end

  test "mentee cannot manage family members" do
    assert_not Authorization.can?(@mentee_user, :manage_family_members, :users)
  end

  test "mentee cannot manage mentees" do
    assert_not Authorization.can?(@mentee_user, :manage_mentees, :users)
  end

  # Volunteer comprehensive permissions
  test "volunteer cannot index users" do
    assert_not Authorization.can?(@volunteer_user, :index, :users)
  end

  test "volunteer cannot edit users" do
    assert_not Authorization.can?(@volunteer_user, :edit, :users)
  end

  test "volunteer cannot delete users" do
    assert_not Authorization.can?(@volunteer_user, :delete, :users, @other_user)
  end

  test "volunteer cannot manage family members" do
    assert_not Authorization.can?(@volunteer_user, :manage_family_members, :users)
  end

  test "volunteer cannot manage mentees" do
    assert_not Authorization.can?(@volunteer_user, :manage_mentees, :users)
  end

  # Navigation comprehensive tests
  test "staff has same navigation as admin" do
    nav = Authorization.navigation_for(@user)
    staff_nav = Authorization.navigation_for(@staff_user)
    assert_equal nav, staff_nav
  end

  test "guardian has limited navigation" do
    nav = Authorization.navigation_for(@guardian_user)
    assert_includes nav, :dashboard
    assert_includes nav, :events
    assert_not_includes nav, :users
    assert_not_includes nav, :teams
  end

  test "volunteer has limited navigation" do
    nav = Authorization.navigation_for(@volunteer_user)
    assert_includes nav, :dashboard
    assert_not_includes nav, :users
  end

  # Self-restriction edge cases
  test "staff cannot delete themselves even though they lack delete permission anyway" do
    assert_not Authorization.can?(@staff_user, :delete, :users, @staff_user)
  end

  test "self-restriction only applies to specific actions" do
    # Admin can edit themselves (edit is not self-restricted)
    assert Authorization.can?(@user, :edit, :users)
  end
end
