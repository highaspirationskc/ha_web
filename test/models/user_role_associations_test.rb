require "test_helper"

class UserRoleAssociationsTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "test@example.com",
      password: "Password123!"
    )
  end

  # Role associations
  test "has one mentor" do
    assert_respond_to @user, :mentor
  end

  test "has one mentee" do
    assert_respond_to @user, :mentee
  end

  test "has one guardian" do
    assert_respond_to @user, :guardian
  end

  test "has one staff" do
    assert_respond_to @user, :staff
  end

  test "has one volunteer" do
    assert_respond_to @user, :volunteer
  end

  # Creating role profiles
  test "can create mentor profile for user" do
    mentor = Mentor.create!(user: @user)
    assert_equal mentor, @user.mentor
  end

  test "can create mentee profile for user" do
    team = Team.create!(name: "Test Team", color: "blue")
    mentee = Mentee.create!(user: @user, team: team)
    assert_equal mentee, @user.mentee
  end

  test "can create guardian profile for user" do
    guardian = Guardian.create!(user: @user)
    assert_equal guardian, @user.guardian
  end

  test "can create staff profile for user" do
    staff = Staff.create!(user: @user)
    assert_equal staff, @user.staff
  end

  test "can create volunteer profile for user" do
    volunteer = Volunteer.create!(user: @user)
    assert_equal volunteer, @user.volunteer
  end

  # User has role check methods (backed by profile associations, not enum)
  test "has role check methods" do
    assert_respond_to @user, :mentor?
    assert_respond_to @user, :mentee?
    assert_respond_to @user, :guardian?
    assert_respond_to @user, :staff?
    assert_respond_to @user, :admin?
    assert_respond_to @user, :volunteer?
  end

  test "role check methods return false without profiles" do
    assert_not @user.mentor?
    assert_not @user.mentee?
    assert_not @user.guardian?
    assert_not @user.staff?
    assert_not @user.admin?
    assert_not @user.volunteer?
  end

  test "role check methods return true with profiles" do
    Mentor.create!(user: @user)
    assert @user.mentor?

    staff = Staff.create!(user: @user, permission_level: :admin)
    assert @user.staff?
    assert @user.admin?
  end

  # User should not have team_id anymore
  test "does not belong to team directly" do
    assert_not_respond_to @user, :team
    assert_not_respond_to @user, :team_id
  end

  # Dependent destroy
  test "destroying user destroys associated mentor profile" do
    Mentor.create!(user: @user)

    assert_difference "Mentor.count", -1 do
      @user.destroy
    end
  end

  test "destroying user destroys associated mentee profile" do
    team = Team.create!(name: "Test Team", color: "blue")
    Mentee.create!(user: @user, team: team)

    assert_difference "Mentee.count", -1 do
      @user.destroy
    end
  end

  test "destroying user destroys associated guardian profile" do
    Guardian.create!(user: @user)

    assert_difference "Guardian.count", -1 do
      @user.destroy
    end
  end

  test "destroying user destroys associated staff profile" do
    Staff.create!(user: @user)

    assert_difference "Staff.count", -1 do
      @user.destroy
    end
  end

  test "destroying user destroys associated volunteer profile" do
    Volunteer.create!(user: @user)

    assert_difference "Volunteer.count", -1 do
      @user.destroy
    end
  end
end
