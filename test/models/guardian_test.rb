require "test_helper"

class GuardianTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "guardian@example.com",
      password: "Password123!"
    )
    @guardian = Guardian.new(user: @user)
  end

  # Associations
  test "belongs to user" do
    assert_respond_to @guardian, :user
    assert_equal @user, @guardian.user
  end

  test "has many family_members" do
    assert_respond_to @guardian, :family_members
  end

  test "has many children through family_members" do
    assert_respond_to @guardian, :children
  end

  # Validations
  test "is valid with a user" do
    assert @guardian.valid?
  end

  test "is invalid without a user" do
    @guardian.user = nil
    assert_not @guardian.valid?
    assert_includes @guardian.errors[:user], "must exist"
  end

  # Children relationships
  test "can have multiple children" do
    @guardian.save!

    team = Team.create!(name: "Test Team", color: "blue")

    mentee_user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    mentee_user2 = User.create!(email: "mentee2@example.com", password: "Password123!")

    mentee1 = Mentee.create!(user: mentee_user1, team: team)
    mentee2 = Mentee.create!(user: mentee_user2, team: team)

    FamilyMember.create!(guardian: @guardian, mentee: mentee1, relationship_type: "parent")
    FamilyMember.create!(guardian: @guardian, mentee: mentee2, relationship_type: "parent")

    assert_includes @guardian.children, mentee1
    assert_includes @guardian.children, mentee2
    assert_equal 2, @guardian.children.count
  end

  test "children with different relationship types" do
    @guardian.save!

    team = Team.create!(name: "Test Team", color: "blue")

    child_user = User.create!(email: "child@example.com", password: "Password123!")
    grandchild_user = User.create!(email: "grandchild@example.com", password: "Password123!")

    child = Mentee.create!(user: child_user, team: team)
    grandchild = Mentee.create!(user: grandchild_user, team: team)

    FamilyMember.create!(guardian: @guardian, mentee: child, relationship_type: "parent")
    FamilyMember.create!(guardian: @guardian, mentee: grandchild, relationship_type: "grandparent")

    assert_includes @guardian.children, child
    assert_includes @guardian.children, grandchild
  end

  test "destroying guardian destroys family_member associations" do
    @guardian.save!
    team = Team.create!(name: "Test Team", color: "blue")
    mentee_user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: mentee_user, team: team)

    FamilyMember.create!(guardian: @guardian, mentee: mentee, relationship_type: "parent")

    assert_difference "FamilyMember.count", -1 do
      @guardian.destroy
    end
  end
end
