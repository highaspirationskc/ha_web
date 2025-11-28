# frozen_string_literal: true

require "test_helper"

class TeamsMutationsTest < ActiveSupport::TestCase
  def setup
    @admin = User.create!(email: "admin@example.com", password: "Password123!", role: :admin)
    @admin.activate!

    @staff = User.create!(email: "staff@example.com", password: "Password123!", role: :staff)
    @staff.activate!

    @mentor = User.create!(email: "mentor@example.com", password: "Password123!", role: :mentor)
    @mentor.activate!

    @team = Team.create!(name: "Existing Team", color: :blue)
  end

  # CreateTeam tests

  test "admin can create team" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
            name
            color
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "New Team",
        color: "red"
      }
    }, context: { current_user: @admin })

    team = result.dig("data", "createTeam", "team")
    errors = result.dig("data", "createTeam", "errors")

    assert_not_nil team
    assert_equal "New Team", team["name"]
    assert_equal "red", team["color"]
    assert_empty errors
  end

  test "staff can create team" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
            name
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "Staff Team",
        color: "green"
      }
    }, context: { current_user: @staff })

    team = result.dig("data", "createTeam", "team")
    errors = result.dig("data", "createTeam", "errors")

    assert_not_nil team
    assert_equal "Staff Team", team["name"]
    assert_empty errors
  end

  test "mentor can create team" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
            name
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "Mentor Team",
        color: "yellow"
      }
    }, context: { current_user: @mentor })

    team = result.dig("data", "createTeam", "team")
    errors = result.dig("data", "createTeam", "errors")

    assert_not_nil team
    assert_equal "Mentor Team", team["name"]
    assert_empty errors
  end

  test "create team with icon_url" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
            name
            iconUrl
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "Icon Team",
        color: "blue",
        iconUrl: "https://example.com/icon.png"
      }
    }, context: { current_user: @admin })

    team = result.dig("data", "createTeam", "team")
    errors = result.dig("data", "createTeam", "errors")

    assert_not_nil team
    assert_equal "https://example.com/icon.png", team["iconUrl"]
    assert_empty errors
  end

  test "create team fails with duplicate name" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "Existing Team",
        color: "red"
      }
    }, context: { current_user: @admin })

    team = result.dig("data", "createTeam", "team")
    errors = result.dig("data", "createTeam", "errors")

    assert_nil team
    assert_includes errors.first, "Name has already been taken"
  end

  test "create team requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateTeamInput!) {
        createTeam(input: $input) {
          team {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        name: "New Team",
        color: "red"
      }
    }, context: {})

    assert_nil result.dig("data", "createTeam")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  # UpdateTeam tests

  test "admin can update team" do
    mutation = <<~GQL
      mutation($input: UpdateTeamInput!) {
        updateTeam(input: $input) {
          team {
            id
            name
            color
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @team.id.to_s,
        name: "Updated Team Name",
        color: "green"
      }
    }, context: { current_user: @admin })

    team = result.dig("data", "updateTeam", "team")
    errors = result.dig("data", "updateTeam", "errors")

    assert_not_nil team
    assert_equal "Updated Team Name", team["name"]
    assert_equal "green", team["color"]
    assert_empty errors
  end

  test "update team returns error for non-existent team" do
    mutation = <<~GQL
      mutation($input: UpdateTeamInput!) {
        updateTeam(input: $input) {
          team {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: "99999",
        name: "Ghost Team"
      }
    }, context: { current_user: @admin })

    team = result.dig("data", "updateTeam", "team")
    errors = result.dig("data", "updateTeam", "errors")

    assert_nil team
    assert_includes errors, "Team not found"
  end

  # DeleteTeam tests

  test "admin can delete team" do
    team_to_delete = Team.create!(name: "Delete Me", color: :red)

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteTeam(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: team_to_delete.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteTeam", "success")
    errors = result.dig("data", "deleteTeam", "errors")

    assert success
    assert_empty errors
    assert_nil Team.find_by(id: team_to_delete.id)
  end

  test "delete team returns error for non-existent team" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteTeam(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: "99999"
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteTeam", "success")
    errors = result.dig("data", "deleteTeam", "errors")

    assert_not success
    assert_includes errors, "Team not found"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
