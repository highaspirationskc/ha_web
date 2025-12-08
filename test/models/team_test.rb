require "test_helper"

class TeamTest < ActiveSupport::TestCase
  def setup
    @team = Team.new(name: "Test Team", color: "blue")
  end

  # Validations
  test "is valid with name and color" do
    assert @team.valid?
  end

  test "is invalid without a name" do
    @team.name = nil
    assert_not @team.valid?
    assert_includes @team.errors[:name], "can't be blank"
  end

  test "is invalid without a color" do
    @team.color = nil
    assert_not @team.valid?
    assert_includes @team.errors[:color], "can't be blank"
  end

  test "name must be unique" do
    @team.save!
    duplicate = Team.new(name: "Test Team", color: "red")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  # Color enum with string values
  test "has color enum" do
    assert_respond_to @team, :color
    assert_respond_to @team, :blue?
    assert_respond_to @team, :green?
    assert_respond_to @team, :yellow?
    assert_respond_to @team, :red?
  end

  test "can set color to blue" do
    @team.color = "blue"
    @team.save!
    assert @team.blue?
  end

  test "can set color to green" do
    @team.color = "green"
    @team.save!
    assert @team.green?
  end

  test "can set color to yellow" do
    @team.color = "yellow"
    @team.save!
    assert @team.yellow?
  end

  test "can set color to red" do
    @team.color = "red"
    @team.save!
    assert @team.red?
  end

  # Associations - now with Mentee instead of User
  test "has many mentees" do
    assert_respond_to @team, :mentees
  end

  test "can have multiple mentees" do
    @team.save!

    user1 = User.create!(email: "mentee1@example.com", password: "Password123!")
    user2 = User.create!(email: "mentee2@example.com", password: "Password123!")

    mentee1 = Mentee.create!(user: user1, team: @team)
    mentee2 = Mentee.create!(user: user2, team: @team)

    assert_includes @team.mentees, mentee1
    assert_includes @team.mentees, mentee2
    assert_equal 2, @team.mentees.count
  end

  test "nullifies mentee team_id when team is destroyed" do
    @team.save!

    user = User.create!(email: "mentee@example.com", password: "Password123!")
    mentee = Mentee.create!(user: user, team: @team)

    @team.destroy

    mentee.reload
    assert_nil mentee.team_id
  end

  # Should not have direct user association anymore
  test "does not have direct users association" do
    assert_not_respond_to @team, :users
    assert_not_respond_to @team, :members
  end
end
