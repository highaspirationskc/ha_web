require "test_helper"

class AuthorizationRedemptionsTest < ActiveSupport::TestCase
  def setup
    @admin_user = User.create!(email: "auth_red_admin@example.com", password: "Password123!")
    Staff.create!(user: @admin_user, permission_level: :admin)

    @staff_user = User.create!(email: "auth_red_staff@example.com", password: "Password123!")
    Staff.create!(user: @staff_user)

    @mentor_user = User.create!(email: "auth_red_mentor@example.com", password: "Password123!")
    Mentor.create!(user: @mentor_user)

    @guardian_user = User.create!(email: "auth_red_guardian@example.com", password: "Password123!")
    Guardian.create!(user: @guardian_user)

    @mentee_user = User.create!(email: "auth_red_mentee@example.com", password: "Password123!")
    Mentee.create!(user: @mentee_user)

    @volunteer_user = User.create!(email: "auth_red_volunteer@example.com", password: "Password123!")
    Volunteer.create!(user: @volunteer_user)
  end

  # Admin can manage redemptions
  test "admin can manage_redemptions on incentives" do
    assert Authorization.can?(@admin_user, :manage_redemptions, :incentives)
  end

  # Staff can manage redemptions
  test "staff can manage_redemptions on incentives" do
    assert Authorization.can?(@staff_user, :manage_redemptions, :incentives)
  end

  # No other roles can manage redemptions
  test "mentor cannot manage_redemptions on incentives" do
    assert_not Authorization.can?(@mentor_user, :manage_redemptions, :incentives)
  end

  test "guardian cannot manage_redemptions on incentives" do
    assert_not Authorization.can?(@guardian_user, :manage_redemptions, :incentives)
  end

  test "mentee cannot manage_redemptions on incentives" do
    assert_not Authorization.can?(@mentee_user, :manage_redemptions, :incentives)
  end

  test "volunteer cannot manage_redemptions on incentives" do
    assert_not Authorization.can?(@volunteer_user, :manage_redemptions, :incentives)
  end
end
