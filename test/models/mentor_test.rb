require "test_helper"

class MentorTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email: "mentor@example.com",
      password: "Password123!"
    )
    @mentor = Mentor.new(user: @user)
  end

  # Associations
  test "belongs to user" do
    assert_respond_to @mentor, :user
    assert_equal @user, @mentor.user
  end

  test "has many mentees" do
    assert_respond_to @mentor, :mentees
  end

  # Validations
  test "is valid with a user" do
    assert @mentor.valid?
  end

  test "is invalid without a user" do
    @mentor.user = nil
    assert_not @mentor.valid?
    assert_includes @mentor.errors[:user], "must exist"
  end

  # Relationships
  test "can have multiple mentees" do
    @mentor.save!

    team = Team.create!(name: "Test Team", color: "blue")

    mentee_user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    mentee_user2 = User.create!(email: "mentee2@example.com", password: "Password123!")

    mentee1 = Mentee.create!(user: mentee_user1, mentor: @mentor, team: team)
    mentee2 = Mentee.create!(user: mentee_user2, mentor: @mentor, team: team)

    assert_includes @mentor.mentees, mentee1
    assert_includes @mentor.mentees, mentee2
    assert_equal 2, @mentor.mentees.count
  end

  test "destroying mentor nullifies mentee associations" do
    @mentor.save!
    team = Team.create!(name: "Test Team", color: "blue")
    mentee_user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: mentee_user, mentor: @mentor, team: team)

    @mentor.destroy

    mentee.reload
    assert_nil mentee.mentor_id
  end
end
