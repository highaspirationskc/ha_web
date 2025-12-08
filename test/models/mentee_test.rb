require "test_helper"

class MenteeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "mentee@example.com",
      password: "Password123!"
    )
    @team = Team.create!(name: "Test Team", color: "blue")
    @mentee = Mentee.new(user: @user, team: @team)
  end

  # Associations
  test "belongs to user" do
    assert_respond_to @mentee, :user
    assert_equal @user, @mentee.user
  end

  test "belongs to team (optional)" do
    assert_respond_to @mentee, :team
    assert_equal @team, @mentee.team
  end

  test "belongs to mentor (optional)" do
    assert_respond_to @mentee, :mentor
  end

  test "has many family_members" do
    assert_respond_to @mentee, :family_members
  end

  test "has many guardians through family_members" do
    assert_respond_to @mentee, :guardians
  end

  # Validations
  test "is valid with a user" do
    assert @mentee.valid?
  end

  test "is invalid without a user" do
    @mentee.user = nil
    assert_not @mentee.valid?
    assert_includes @mentee.errors[:user], "must exist"
  end

  test "is valid without a team" do
    @mentee.team = nil
    assert @mentee.valid?
  end

  test "is valid without a mentor" do
    @mentee.mentor = nil
    assert @mentee.valid?
  end

  # Mentor relationship
  test "can be assigned to a mentor" do
    mentor_user = User.create!(email: "mentor@example.com", password: "Password123!")
    mentor = Mentor.create!(user: mentor_user)

    @mentee.mentor = mentor
    @mentee.save!

    assert_equal mentor, @mentee.mentor
  end

  # Guardian relationships
  test "can have multiple guardians" do
    @mentee.save!

    guardian_user1 = User.create!(email: "guardian1@example.com", password: "Password123!")
    guardian_user2 = User.create!(email: "guardian2@example.com", password: "Password123!")

    guardian1 = Guardian.create!(user: guardian_user1)
    guardian2 = Guardian.create!(user: guardian_user2)

    FamilyMember.create!(guardian: guardian1, mentee: @mentee, relationship_type: "parent")
    FamilyMember.create!(guardian: guardian2, mentee: @mentee, relationship_type: "grandparent")

    assert_includes @mentee.guardians, guardian1
    assert_includes @mentee.guardians, guardian2
    assert_equal 2, @mentee.guardians.count
  end

  # Team relationship
  test "can be assigned to a team" do
    new_team = Team.create!(name: "New Team", color: "red")
    @mentee.team = new_team
    @mentee.save!

    assert_equal new_team, @mentee.team
  end
end
