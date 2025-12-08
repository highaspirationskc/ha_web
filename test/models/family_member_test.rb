require "test_helper"

class FamilyMemberTest < ActiveSupport::TestCase
  def setup
    @guardian_user = User.create!(email: "guardian@example.com", password: "Password123!")
    @mentee_user = User.create!(email: "mentee@example.com", password: "Password123!")

    @guardian = Guardian.create!(user: @guardian_user)
    @team = Team.create!(name: "Test Team", color: "blue")
    @mentee = Mentee.create!(user: @mentee_user, team: @team)

    @family_member = FamilyMember.new(
      guardian: @guardian,
      mentee: @mentee,
      relationship_type: "parent"
    )
  end

  # Associations
  test "belongs to guardian" do
    assert_respond_to @family_member, :guardian
    assert_equal @guardian, @family_member.guardian
  end

  test "belongs to mentee" do
    assert_respond_to @family_member, :mentee
    assert_equal @mentee, @family_member.mentee
  end

  # Validations
  test "is valid with guardian, mentee, and relationship_type" do
    assert @family_member.valid?
  end

  test "is invalid without a guardian" do
    @family_member.guardian = nil
    assert_not @family_member.valid?
  end

  test "is invalid without a mentee" do
    @family_member.mentee = nil
    assert_not @family_member.valid?
  end

  test "is invalid without a relationship_type" do
    @family_member.relationship_type = nil
    assert_not @family_member.valid?
  end

  # Relationship type enum
  test "has relationship_type enum with string values" do
    assert_respond_to @family_member, :relationship_type
    assert_respond_to @family_member, :parent?
    assert_respond_to @family_member, :grandparent?
    assert_respond_to @family_member, :aunt_uncle?
    assert_respond_to @family_member, :sibling?
    assert_respond_to @family_member, :other?
  end

  test "can be parent relationship" do
    @family_member.relationship_type = "parent"
    @family_member.save!
    assert @family_member.parent?
  end

  test "can be grandparent relationship" do
    @family_member.relationship_type = "grandparent"
    @family_member.save!
    assert @family_member.grandparent?
  end

  test "can be aunt_uncle relationship" do
    @family_member.relationship_type = "aunt_uncle"
    @family_member.save!
    assert @family_member.aunt_uncle?
  end

  test "can be sibling relationship" do
    @family_member.relationship_type = "sibling"
    @family_member.save!
    assert @family_member.sibling?
  end

  test "can be other relationship" do
    @family_member.relationship_type = "other"
    @family_member.save!
    assert @family_member.other?
  end

  # Uniqueness
  test "guardian-mentee pair must be unique" do
    @family_member.save!

    duplicate = FamilyMember.new(
      guardian: @guardian,
      mentee: @mentee,
      relationship_type: "grandparent"
    )

    assert_not duplicate.valid?
  end

  # Scopes
  test "relationship_type scopes work" do
    @family_member.save!

    grandparent_user = User.create!(email: "grandparent@example.com", password: "Password123!")
    grandparent = Guardian.create!(user: grandparent_user)

    grandparent_relation = FamilyMember.create!(
      guardian: grandparent,
      mentee: @mentee,
      relationship_type: "grandparent"
    )

    assert_includes FamilyMember.parent, @family_member
    assert_not_includes FamilyMember.parent, grandparent_relation
    assert_includes FamilyMember.grandparent, grandparent_relation
    assert_not_includes FamilyMember.grandparent, @family_member
  end
end
