require "test_helper"

class VolunteerTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "volunteer@example.com",
      password: "Password123!"
    )
    @volunteer = Volunteer.new(user: @user)
  end

  # Associations
  test "belongs to user" do
    assert_respond_to @volunteer, :user
    assert_equal @user, @volunteer.user
  end

  # Validations
  test "is valid with a user" do
    assert @volunteer.valid?
  end

  test "is invalid without a user" do
    @volunteer.user = nil
    assert_not @volunteer.valid?
    assert_includes @volunteer.errors[:user], "must exist"
  end
end
