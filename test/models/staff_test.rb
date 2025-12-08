require "test_helper"

class StaffTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "staff@example.com",
      password: "Password123!"
    )
    @staff = Staff.new(user: @user)
  end

  # Associations
  test "belongs to user" do
    assert_respond_to @staff, :user
    assert_equal @user, @staff.user
  end

  # Validations
  test "is valid with a user" do
    assert @staff.valid?
  end

  test "is invalid without a user" do
    @staff.user = nil
    assert_not @staff.valid?
    assert_includes @staff.errors[:user], "must exist"
  end

  # Permission level enum
  test "has permission_level enum" do
    assert_respond_to @staff, :permission_level
    assert_respond_to @staff, :standard?
    assert_respond_to @staff, :admin?
  end

  test "defaults to standard permission level" do
    @staff.save!
    assert @staff.standard?
  end

  test "can be set to admin permission level" do
    @staff.permission_level = "admin"
    @staff.save!
    assert @staff.admin?
  end

  test "permission_level scopes work" do
    @staff.save!

    user = User.create!(email: "admin@example.com", password: "Password123!")
    staff = Staff.create!(user: user, permission_level: "admin")

    assert_includes Staff.standard, @staff
    assert_not_includes Staff.standard, staff
    assert_includes Staff.admin, staff
    assert_not_includes Staff.admin, @staff
  end
end
