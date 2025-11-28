require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  # Validations
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "email should be unique" do
    @user.save!
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "email should accept valid format" do
    valid_emails = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp]
    valid_emails.each do |valid_email|
      @user.email = valid_email
      assert @user.valid?, "#{valid_email.inspect} should be valid"
    end
  end

  test "email should reject invalid format" do
    invalid_emails = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com]
    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email.inspect} should be invalid"
    end
  end

  test "email should be saved as lowercase" do
    mixed_case_email = "TeSt@ExAmPlE.CoM"
    @user.email = mixed_case_email
    @user.save!
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "password should be at least 8 characters" do
    @user.password = @user.password_confirmation = "Pass1!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "password should contain uppercase letter" do
    @user.password = @user.password_confirmation = "password123!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one uppercase letter"
  end

  test "password should contain number" do
    @user.password = @user.password_confirmation = "Password!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one number"
  end

  test "password should contain special character" do
    @user.password = @user.password_confirmation = "Password123"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one special character"
  end

  # Role enum
  test "should have role enum" do
    assert_respond_to @user, :role
    assert_respond_to @user, :volunteer?
    assert_respond_to @user, :mentor?
    assert_respond_to @user, :mentee?
    assert_respond_to @user, :parent?
    assert_respond_to @user, :staff?
    assert_respond_to @user, :admin?
  end

  test "should default to admin role" do
    user = User.create!(email: "new@example.com", password: "Password123!")
    assert user.admin?
  end

  test "should have working role scopes" do
    admin = User.create!(email: "admin@example.com", password: "Password123!", role: :admin)
    staff = User.create!(email: "staff@example.com", password: "Password123!", role: :staff)

    assert_includes User.admin, admin
    assert_not_includes User.admin, staff
    assert_includes User.staff, staff
    assert_not_includes User.staff, admin
  end

  # Associations
  test "should have many tokens" do
    assert_respond_to @user, :tokens
  end

  test "should destroy associated tokens when user is destroyed" do
    @user.save!
    @user.tokens.create!(token_hash: "test_hash_123")
    assert_difference "Token.count", -1 do
      @user.destroy
    end
  end

  # Active status
  test "should default to inactive" do
    user = User.create!(email: "inactive@example.com", password: "Password123!")
    assert_not user.active?
  end

  # Confirmation token
  test "should generate confirmation token on create" do
    user = User.create!(email: "confirm@example.com", password: "Password123!")
    assert_not_nil user.confirmation_token
    assert_not_nil user.confirmation_sent_at
  end

  test "activate! should set active to true and clear confirmation token" do
    @user.save!
    assert_not @user.active?
    assert_not_nil @user.confirmation_token

    @user.activate!

    assert @user.active?
    assert_nil @user.confirmation_token
    assert_nil @user.confirmation_sent_at
  end

  test "deactivate! should set active to false" do
    @user.save!
    @user.activate!
    assert @user.active?

    @user.deactivate!

    assert_not @user.active?
  end

  test "send_confirmation_email should queue email delivery" do
    @user.save!
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      @user.send_confirmation_email
    end
  end

  # Relationship methods - Only parent-child relationships exist
  # Mentors/volunteers manage mentees via team membership, not relationships

  # team_mentees - for mentors/volunteers to see mentees on their team
  test "mentor#team_mentees returns all mentees on same team" do
    team = Team.create!(name: "Test Team", color: :blue)
    mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor, team: team)
    mentee1 = User.create!(email: "mentee1@example.com", password: "Password123!", role: :mentee, team: team)
    mentee2 = User.create!(email: "mentee2@example.com", password: "Password123!", role: :mentee, team: team)
    other_team = Team.create!(name: "Other Team", color: :red)
    mentee_other_team = User.create!(email: "mentee3@example.com", password: "Password123!", role: :mentee, team: other_team)

    assert_includes mentor.team_mentees, mentee1
    assert_includes mentor.team_mentees, mentee2
    assert_not_includes mentor.team_mentees, mentee_other_team
  end

  test "mentor#team_mentees returns empty when mentor has no team" do
    mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor)
    assert_empty mentor.team_mentees
  end

  test "volunteer#team_mentees returns all mentees on same team" do
    team = Team.create!(name: "Test Team", color: :blue)
    volunteer = User.create!(email: "volunteer@example.com", password: "Password123!", role: :volunteer, team: team)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee, team: team)

    assert_includes volunteer.team_mentees, mentee
  end

  test "non-team-member#team_mentees returns empty" do
    team = Team.create!(name: "Test Team", color: :blue)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee, team: team)
    parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)

    assert_empty mentee.team_mentees
    assert_empty parent.team_mentees
  end

  # Parent-child relationships (explicit FamilyMember)
  test "parent#children returns mentees linked via parent relationship" do
    parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)
    child1 = User.create!(email: "child1@example.com", password: "Password123!", role: :mentee)
    child2 = User.create!(email: "child2@example.com", password: "Password123!", role: :mentee)
    other_mentee = User.create!(email: "other@example.com", password: "Password123!", role: :mentee)

    FamilyMember.create!(user: parent, related_user: child1, relationship_type: :parent)
    FamilyMember.create!(user: parent, related_user: child2, relationship_type: :parent)

    assert_includes parent.children, child1
    assert_includes parent.children, child2
    assert_not_includes parent.children, other_mentee
  end

  test "mentee#parents returns parents linked via parent relationship" do
    parent1 = User.create!(email: "parent1@example.com", password: "Password123!", role: :parent)
    parent2 = User.create!(email: "parent2@example.com", password: "Password123!", role: :parent)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee)
    other_parent = User.create!(email: "other@example.com", password: "Password123!", role: :parent)

    FamilyMember.create!(user: parent1, related_user: mentee, relationship_type: :parent)
    FamilyMember.create!(user: parent2, related_user: mentee, relationship_type: :parent)

    assert_includes mentee.parents, parent1
    assert_includes mentee.parents, parent2
    assert_not_includes mentee.parents, other_parent
  end

  test "non-parent#children returns empty" do
    mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor)
    assert_empty mentor.children
  end

  test "non-mentee#parents returns empty" do
    parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)
    assert_empty parent.parents
  end

  # can_manage? permission checks
  test "admin can_manage? any user" do
    admin = User.create!(email: "admin@example.com", password: "Password123!", role: :admin)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee)

    assert admin.can_manage?(mentee)
  end

  test "staff can_manage? any user" do
    staff = User.create!(email: "staff@example.com", password: "Password123!", role: :staff)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee)

    assert staff.can_manage?(mentee)
  end

  test "mentor can_manage? mentees on their team" do
    team = Team.create!(name: "Test Team", color: :blue)
    mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor, team: team)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee, team: team)

    assert mentor.can_manage?(mentee)
  end

  test "mentor cannot manage mentees on other teams" do
    team1 = Team.create!(name: "Team 1", color: :blue)
    team2 = Team.create!(name: "Team 2", color: :red)
    mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor, team: team1)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee, team: team2)

    assert_not mentor.can_manage?(mentee)
  end

  test "mentor without team cannot manage anyone except self" do
    mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee)

    assert_not mentor.can_manage?(mentee)
    assert mentor.can_manage?(mentor)
  end

  test "volunteer can_manage? mentees on their team" do
    team = Team.create!(name: "Test Team", color: :blue)
    volunteer = User.create!(email: "volunteer@example.com", password: "Password123!", role: :volunteer, team: team)
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee, team: team)

    assert volunteer.can_manage?(mentee)
  end

  test "parent can_manage? their children" do
    parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)
    child = User.create!(email: "child@example.com", password: "Password123!", role: :mentee)
    FamilyMember.create!(user: parent, related_user: child, relationship_type: :parent)

    assert parent.can_manage?(child)
  end

  test "parent cannot manage other mentees" do
    parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)
    other_mentee = User.create!(email: "other@example.com", password: "Password123!", role: :mentee)

    assert_not parent.can_manage?(other_mentee)
  end

  test "mentee cannot manage anyone except self" do
    mentee1 = User.create!(email: "mentee1@example.com", password: "Password123!", role: :mentee)
    mentee2 = User.create!(email: "mentee2@example.com", password: "Password123!", role: :mentee)

    assert_not mentee1.can_manage?(mentee2)
    assert mentee1.can_manage?(mentee1)
  end

  test "user can always manage themselves" do
    mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee)
    parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)

    assert mentee.can_manage?(mentee)
    assert parent.can_manage?(parent)
  end
end
