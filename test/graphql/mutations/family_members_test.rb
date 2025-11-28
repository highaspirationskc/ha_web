# frozen_string_literal: true

require "test_helper"

class FamilyMembersMutationsTest < ActiveSupport::TestCase
  def setup
    @team = Team.create!(name: "Test Team", color: :blue)

    @admin = User.create!(email: "admin@example.com", password: "Password123!", role: :admin)
    @admin.activate!

    @staff = User.create!(email: "staff@example.com", password: "Password123!", role: :staff)
    @staff.activate!

    @mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor, team: @team)
    @mentor.activate!

    @mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee)
    @mentee.activate!

    @mentee_on_team = User.create!(email: "mentee2@example.com", password: "Password123!", role: :mentee, team: @team)
    @mentee_on_team.activate!

    @parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)
    @parent.activate!
  end

  # CreateFamilyMember tests
  # Only superusers (admin/staff) can create family member relationships

  test "admin can create parent family member" do
    mutation = <<~GQL
      mutation($input: CreateFamilyMemberInput!) {
        createFamilyMember(input: $input) {
          familyMember {
            id
            relationshipType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @parent.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "parent"
      }
    }, context: { current_user: @admin })

    family_member = result.dig("data", "createFamilyMember", "familyMember")
    errors = result.dig("data", "createFamilyMember", "errors")

    assert_not_nil family_member
    assert_equal "parent", family_member["relationshipType"]
    assert_empty errors
  end

  test "staff can create parent family member" do
    mutation = <<~GQL
      mutation($input: CreateFamilyMemberInput!) {
        createFamilyMember(input: $input) {
          familyMember {
            id
            relationshipType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @parent.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "parent"
      }
    }, context: { current_user: @staff })

    family_member = result.dig("data", "createFamilyMember", "familyMember")
    errors = result.dig("data", "createFamilyMember", "errors")

    assert_not_nil family_member
    assert_equal "parent", family_member["relationshipType"]
    assert_empty errors
  end

  test "admin can create guardian family member" do
    mutation = <<~GQL
      mutation($input: CreateFamilyMemberInput!) {
        createFamilyMember(input: $input) {
          familyMember {
            id
            relationshipType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @parent.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "guardian"
      }
    }, context: { current_user: @admin })

    family_member = result.dig("data", "createFamilyMember", "familyMember")
    errors = result.dig("data", "createFamilyMember", "errors")

    assert_not_nil family_member
    assert_equal "guardian", family_member["relationshipType"]
    assert_empty errors
  end

  test "mentor cannot create family members" do
    mutation = <<~GQL
      mutation($input: CreateFamilyMemberInput!) {
        createFamilyMember(input: $input) {
          familyMember {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @parent.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "parent"
      }
    }, context: { current_user: @mentor })

    family_member = result.dig("data", "createFamilyMember", "familyMember")
    errors = result.dig("data", "createFamilyMember", "errors")

    assert_nil family_member
    assert_includes errors, "You don't have permission to create this relationship"
  end

  test "parent cannot create family members" do
    mutation = <<~GQL
      mutation($input: CreateFamilyMemberInput!) {
        createFamilyMember(input: $input) {
          familyMember {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @parent.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "parent"
      }
    }, context: { current_user: @parent })

    family_member = result.dig("data", "createFamilyMember", "familyMember")
    errors = result.dig("data", "createFamilyMember", "errors")

    assert_nil family_member
    assert_includes errors, "You don't have permission to create this relationship"
  end

  test "mentee cannot create family members" do
    mutation = <<~GQL
      mutation($input: CreateFamilyMemberInput!) {
        createFamilyMember(input: $input) {
          familyMember {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @parent.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "parent"
      }
    }, context: { current_user: @mentee })

    family_member = result.dig("data", "createFamilyMember", "familyMember")
    errors = result.dig("data", "createFamilyMember", "errors")

    assert_nil family_member
    assert_includes errors, "You don't have permission to create this relationship"
  end

  # DeleteFamilyMember tests
  # Only superusers (admin/staff) can delete family members

  test "admin can delete any family member" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteFamilyMember(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: family_member.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteFamilyMember", "success")
    errors = result.dig("data", "deleteFamilyMember", "errors")

    assert success
    assert_empty errors
    assert_nil FamilyMember.find_by(id: family_member.id)
  end

  test "staff can delete any family member" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteFamilyMember(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: family_member.id.to_s
    }, context: { current_user: @staff })

    success = result.dig("data", "deleteFamilyMember", "success")
    errors = result.dig("data", "deleteFamilyMember", "errors")

    assert success
    assert_empty errors
    assert_nil FamilyMember.find_by(id: family_member.id)
  end

  test "mentor cannot delete family members" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteFamilyMember(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: family_member.id.to_s
    }, context: { current_user: @mentor })

    success = result.dig("data", "deleteFamilyMember", "success")
    errors = result.dig("data", "deleteFamilyMember", "errors")

    assert_not success
    assert_includes errors, "You don't have permission to delete this relationship"
  end

  test "parent cannot delete family members" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteFamilyMember(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: family_member.id.to_s
    }, context: { current_user: @parent })

    success = result.dig("data", "deleteFamilyMember", "success")
    errors = result.dig("data", "deleteFamilyMember", "errors")

    assert_not success
    assert_includes errors, "You don't have permission to delete this relationship"
  end

  test "mentee cannot delete family members" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteFamilyMember(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: family_member.id.to_s
    }, context: { current_user: @mentee })

    success = result.dig("data", "deleteFamilyMember", "success")
    errors = result.dig("data", "deleteFamilyMember", "errors")

    assert_not success
    assert_includes errors, "You don't have permission to delete this relationship"
  end

  # UpdateFamilyMember tests

  test "admin can update any family member" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($input: UpdateFamilyMemberInput!) {
        updateFamilyMember(input: $input) {
          familyMember {
            id
            relationshipType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: family_member.id.to_s,
        relationshipType: "guardian"
      }
    }, context: { current_user: @admin })

    updated = result.dig("data", "updateFamilyMember", "familyMember")
    errors = result.dig("data", "updateFamilyMember", "errors")

    assert_not_nil updated
    assert_equal "guardian", updated["relationshipType"]
    assert_empty errors
  end

  test "staff can update any family member" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($input: UpdateFamilyMemberInput!) {
        updateFamilyMember(input: $input) {
          familyMember {
            id
            relationshipType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: family_member.id.to_s,
        relationshipType: "guardian"
      }
    }, context: { current_user: @staff })

    updated = result.dig("data", "updateFamilyMember", "familyMember")
    errors = result.dig("data", "updateFamilyMember", "errors")

    assert_not_nil updated
    assert_equal "guardian", updated["relationshipType"]
    assert_empty errors
  end

  test "mentor cannot update family members" do
    family_member = FamilyMember.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($input: UpdateFamilyMemberInput!) {
        updateFamilyMember(input: $input) {
          familyMember {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: family_member.id.to_s,
        relationshipType: "guardian"
      }
    }, context: { current_user: @mentor })

    updated = result.dig("data", "updateFamilyMember", "familyMember")
    errors = result.dig("data", "updateFamilyMember", "errors")

    assert_nil updated
    assert_includes errors, "You don't have permission to update this relationship"
  end

  # Authentication tests

  test "create family member requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateFamilyMemberInput!) {
        createFamilyMember(input: $input) {
          familyMember {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @parent.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "parent"
      }
    }, context: {})

    assert_nil result.dig("data", "createFamilyMember")
    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
