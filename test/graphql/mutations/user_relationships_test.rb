# frozen_string_literal: true

require "test_helper"

class UserRelationshipsMutationsTest < ActiveSupport::TestCase
  def setup
    @team = Team.create!(name: "Test Team", color: :blue)

    @admin = User.create!(email: "admin@example.com", password: "Password123!", role: :admin)
    @admin.activate!

    @mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor, team: @team)
    @mentor.activate!

    @mentor_no_team = User.create!(email: "mentor2@example.com", password: "Password123!", role: :mentor)
    @mentor_no_team.activate!

    @mentee = User.create!(email: "mentee@example.com", password: "Password123!", role: :mentee)
    @mentee.activate!

    @mentee_on_team = User.create!(email: "mentee2@example.com", password: "Password123!", role: :mentee, team: @team)
    @mentee_on_team.activate!

    @parent = User.create!(email: "parent@example.com", password: "Password123!", role: :parent)
    @parent.activate!
  end

  # CreateUserRelationship tests

  test "admin can create any relationship" do
    mutation = <<~GQL
      mutation($input: CreateUserRelationshipInput!) {
        createUserRelationship(input: $input) {
          userRelationship {
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

    relationship = result.dig("data", "createUserRelationship", "userRelationship")
    errors = result.dig("data", "createUserRelationship", "errors")

    assert_not_nil relationship
    assert_equal "parent", relationship["relationshipType"]
    assert_empty errors
  end

  test "mentor can add mentee relationship" do
    mutation = <<~GQL
      mutation($input: CreateUserRelationshipInput!) {
        createUserRelationship(input: $input) {
          userRelationship {
            id
            relationshipType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @mentor.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "mentor"
      }
    }, context: { current_user: @mentor })

    relationship = result.dig("data", "createUserRelationship", "userRelationship")
    errors = result.dig("data", "createUserRelationship", "errors")

    assert_not_nil relationship
    assert_equal "mentor", relationship["relationshipType"]
    assert_empty errors
  end

  test "mentor adding mentee assigns mentee to mentor's team" do
    assert_nil @mentee.team_id

    mutation = <<~GQL
      mutation($input: CreateUserRelationshipInput!) {
        createUserRelationship(input: $input) {
          userRelationship {
            id
          }
          errors
        }
      }
    GQL

    execute_graphql(mutation, variables: {
      input: {
        userId: @mentor.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "mentor"
      }
    }, context: { current_user: @mentor })

    @mentee.reload
    assert_equal @team.id, @mentee.team_id
  end

  test "mentor without team cannot add mentee" do
    mutation = <<~GQL
      mutation($input: CreateUserRelationshipInput!) {
        createUserRelationship(input: $input) {
          userRelationship {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @mentor_no_team.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "mentor"
      }
    }, context: { current_user: @mentor_no_team })

    relationship = result.dig("data", "createUserRelationship", "userRelationship")
    errors = result.dig("data", "createUserRelationship", "errors")

    assert_nil relationship
    assert_includes errors, "You don't have permission to create this relationship"
  end

  test "mentor cannot create parent relationship" do
    mutation = <<~GQL
      mutation($input: CreateUserRelationshipInput!) {
        createUserRelationship(input: $input) {
          userRelationship {
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

    relationship = result.dig("data", "createUserRelationship", "userRelationship")
    errors = result.dig("data", "createUserRelationship", "errors")

    assert_nil relationship
    assert_includes errors, "You don't have permission to create this relationship"
  end

  test "mentee cannot create relationships" do
    mutation = <<~GQL
      mutation($input: CreateUserRelationshipInput!) {
        createUserRelationship(input: $input) {
          userRelationship {
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

    relationship = result.dig("data", "createUserRelationship", "userRelationship")
    errors = result.dig("data", "createUserRelationship", "errors")

    assert_nil relationship
    assert_includes errors, "You don't have permission to create this relationship"
  end

  # DeleteUserRelationship tests

  test "admin can delete any relationship" do
    relationship = UserRelationship.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUserRelationship(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: relationship.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteUserRelationship", "success")
    errors = result.dig("data", "deleteUserRelationship", "errors")

    assert success
    assert_empty errors
    assert_nil UserRelationship.find_by(id: relationship.id)
  end

  test "mentor can delete their own mentor relationship" do
    relationship = UserRelationship.create!(
      user: @mentor,
      related_user: @mentee_on_team,
      relationship_type: :mentor
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUserRelationship(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: relationship.id.to_s
    }, context: { current_user: @mentor })

    success = result.dig("data", "deleteUserRelationship", "success")
    errors = result.dig("data", "deleteUserRelationship", "errors")

    assert success
    assert_empty errors
  end

  test "mentor cannot delete other relationships" do
    relationship = UserRelationship.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUserRelationship(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: relationship.id.to_s
    }, context: { current_user: @mentor })

    success = result.dig("data", "deleteUserRelationship", "success")
    errors = result.dig("data", "deleteUserRelationship", "errors")

    assert_not success
    assert_includes errors, "You don't have permission to delete this relationship"
  end

  test "mentee cannot delete relationships" do
    relationship = UserRelationship.create!(
      user: @parent,
      related_user: @mentee,
      relationship_type: :parent
    )

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUserRelationship(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: relationship.id.to_s
    }, context: { current_user: @mentee })

    success = result.dig("data", "deleteUserRelationship", "success")
    errors = result.dig("data", "deleteUserRelationship", "errors")

    assert_not success
    assert_includes errors, "You don't have permission to delete this relationship"
  end

  # UpdateUserRelationship tests

  test "admin can update any relationship" do
    relationship = UserRelationship.create!(
      user: @mentor,
      related_user: @mentee_on_team,
      relationship_type: :mentor
    )

    mutation = <<~GQL
      mutation($input: UpdateUserRelationshipInput!) {
        updateUserRelationship(input: $input) {
          userRelationship {
            id
            relationshipType
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: relationship.id.to_s,
        relationshipType: "guardian"
      }
    }, context: { current_user: @admin })

    updated = result.dig("data", "updateUserRelationship", "userRelationship")
    errors = result.dig("data", "updateUserRelationship", "errors")

    assert_not_nil updated
    assert_equal "guardian", updated["relationshipType"]
    assert_empty errors
  end

  test "mentor cannot update relationships" do
    relationship = UserRelationship.create!(
      user: @mentor,
      related_user: @mentee_on_team,
      relationship_type: :mentor
    )

    mutation = <<~GQL
      mutation($input: UpdateUserRelationshipInput!) {
        updateUserRelationship(input: $input) {
          userRelationship {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: relationship.id.to_s,
        relationshipType: "guardian"
      }
    }, context: { current_user: @mentor })

    updated = result.dig("data", "updateUserRelationship", "userRelationship")
    errors = result.dig("data", "updateUserRelationship", "errors")

    assert_nil updated
    assert_includes errors, "You don't have permission to update this relationship"
  end

  # Authentication tests

  test "create relationship requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateUserRelationshipInput!) {
        createUserRelationship(input: $input) {
          userRelationship {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        userId: @mentor.id.to_s,
        relatedUserId: @mentee.id.to_s,
        relationshipType: "mentor"
      }
    }, context: {})

    assert_nil result.dig("data", "createUserRelationship")
    assert_not_nil result["errors"]
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
