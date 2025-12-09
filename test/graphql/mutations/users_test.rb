# frozen_string_literal: true

require "test_helper"

class UsersMutationsTest < ActiveSupport::TestCase
  def setup
    @team = Team.create!(name: "Test Team", color: :blue)

    @admin = create_user(email: "admin@example.com")
    @staff = create_staff_user(email: "staff@example.com")
    @mentor = create_mentor_user(email: "mentor@example.com")
    @mentee = create_mentee_user(email: "mentee@example.com")
  end

  # CreateUser tests

  test "admin can create mentor user" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            email
            role
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newuser@example.com",
        password: "Password123!",
        role: "mentor"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_not_nil user
    assert_equal "newuser@example.com", user["email"]
    assert_equal "Mentor", user["role"]
    assert_empty errors

    created_user = User.find_by(email: "newuser@example.com")
    assert_not_nil created_user.mentor
  end

  test "staff can create user" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            email
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newuser2@example.com",
        password: "Password123!",
        role: "volunteer"
      }
    }, context: { current_user: @staff })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_not_nil user
    assert_empty errors

    created_user = User.find_by(email: "newuser2@example.com")
    assert_not_nil created_user.volunteer
  end

  test "can create staff user with admin permission" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            email
            role
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newadmin@example.com",
        password: "Password123!",
        role: "staff",
        permissionLevel: "admin"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_not_nil user
    assert_equal "Admin", user["role"]
    assert_empty errors

    created_user = User.find_by(email: "newadmin@example.com")
    assert created_user.staff.admin?
  end

  test "can create staff user with standard permission" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            role
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newstaff@example.com",
        password: "Password123!",
        role: "staff",
        permissionLevel: "standard"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_not_nil user
    assert_equal "Staff", user["role"]
    assert_empty errors

    created_user = User.find_by(email: "newstaff@example.com")
    assert created_user.staff.standard?
  end

  test "can create mentee user with team and mentor" do
    mentor_user = create_mentor_user(email: "mentor2@example.com")

    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            role
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newmentee@example.com",
        password: "Password123!",
        role: "mentee",
        teamId: @team.id.to_s,
        mentorId: mentor_user.mentor.id.to_s
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_not_nil user
    assert_equal "Mentee", user["role"]
    assert_empty errors

    created_user = User.find_by(email: "newmentee@example.com")
    assert_not_nil created_user.mentee
    assert_equal @team, created_user.mentee.team
    assert_equal mentor_user.mentor, created_user.mentee.mentor
  end

  test "can create guardian user" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            role
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newguardian@example.com",
        password: "Password123!",
        role: "guardian"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_not_nil user
    assert_equal "Guardian", user["role"]
    assert_empty errors

    created_user = User.find_by(email: "newguardian@example.com")
    assert_not_nil created_user.guardian
  end

  test "can create user without password (generates random)" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            email
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "nopassword@example.com",
        role: "mentor"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_not_nil user
    assert_empty errors

    created_user = User.find_by(email: "nopassword@example.com")
    assert created_user.password_digest.present?
  end

  test "user is active by default" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
            active
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "activeuser@example.com",
        role: "mentor"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "createUser", "user")
    assert user["active"]
  end

  test "mentor cannot create user" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newuser@example.com",
        password: "Password123!",
        role: "mentor"
      }
    }, context: { current_user: @mentor })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_nil user
    assert_includes errors, "You don't have permission to create users"
  end

  test "mentee cannot create user" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newuser@example.com",
        password: "Password123!",
        role: "mentor"
      }
    }, context: { current_user: @mentee })

    user = result.dig("data", "createUser", "user")
    errors = result.dig("data", "createUser", "errors")

    assert_nil user
    assert_includes errors, "You don't have permission to create users"
  end

  test "create user requires authentication" do
    mutation = <<~GQL
      mutation($input: CreateUserInput!) {
        createUser(input: $input) {
          user {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        email: "newuser@example.com",
        password: "Password123!",
        role: "mentor"
      }
    }, context: {})

    assert_nil result.dig("data", "createUser")
    assert_includes result["errors"].first["message"], "Authentication required"
  end

  # UpdateUser tests

  test "admin can update any user" do
    mutation = <<~GQL
      mutation($input: UpdateUserInput!) {
        updateUser(input: $input) {
          user {
            id
            firstName
            lastName
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @mentee.id.to_s,
        firstName: "Updated",
        lastName: "Name"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "updateUser", "user")
    errors = result.dig("data", "updateUser", "errors")

    assert_not_nil user
    assert_equal "Updated", user["firstName"]
    assert_equal "Name", user["lastName"]
    assert_empty errors
  end

  test "staff can update any user" do
    mutation = <<~GQL
      mutation($input: UpdateUserInput!) {
        updateUser(input: $input) {
          user {
            id
            firstName
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @mentee.id.to_s,
        firstName: "StaffUpdated"
      }
    }, context: { current_user: @staff })

    user = result.dig("data", "updateUser", "user")
    errors = result.dig("data", "updateUser", "errors")

    assert_not_nil user
    assert_equal "StaffUpdated", user["firstName"]
    assert_empty errors
  end

  test "mentor cannot update other users" do
    mutation = <<~GQL
      mutation($input: UpdateUserInput!) {
        updateUser(input: $input) {
          user {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @mentee.id.to_s,
        firstName: "Hacked"
      }
    }, context: { current_user: @mentor })

    user = result.dig("data", "updateUser", "user")
    errors = result.dig("data", "updateUser", "errors")

    assert_nil user
    assert_includes errors, "You don't have permission to update this user"
  end

  test "user can update own password" do
    mutation = <<~GQL
      mutation($input: UpdateUserInput!) {
        updateUser(input: $input) {
          user {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @mentee.id.to_s,
        password: "NewPassword123!"
      }
    }, context: { current_user: @mentee })

    user = result.dig("data", "updateUser", "user")
    errors = result.dig("data", "updateUser", "errors")

    assert_not_nil user
    assert_empty errors
  end

  test "user cannot update other fields for themselves" do
    mutation = <<~GQL
      mutation($input: UpdateUserInput!) {
        updateUser(input: $input) {
          user {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: @mentee.id.to_s,
        firstName: "HackedName"
      }
    }, context: { current_user: @mentee })

    user = result.dig("data", "updateUser", "user")
    errors = result.dig("data", "updateUser", "errors")

    assert_nil user
    assert_includes errors, "You don't have permission to update this user"
  end

  test "update user returns error for non-existent user" do
    mutation = <<~GQL
      mutation($input: UpdateUserInput!) {
        updateUser(input: $input) {
          user {
            id
          }
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      input: {
        id: "99999",
        firstName: "Test"
      }
    }, context: { current_user: @admin })

    user = result.dig("data", "updateUser", "user")
    errors = result.dig("data", "updateUser", "errors")

    assert_nil user
    assert_includes errors, "User not found"
  end

  # DeleteUser tests

  test "admin can delete user" do
    user_to_delete = User.create!(email: "delete@example.com", password: "Password123!")

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUser(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: user_to_delete.id.to_s
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteUser", "success")
    errors = result.dig("data", "deleteUser", "errors")

    assert success
    assert_empty errors
    assert_nil User.find_by(id: user_to_delete.id)
  end

  test "staff can delete user" do
    user_to_delete = User.create!(email: "delete2@example.com", password: "Password123!")

    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUser(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: user_to_delete.id.to_s
    }, context: { current_user: @staff })

    success = result.dig("data", "deleteUser", "success")
    errors = result.dig("data", "deleteUser", "errors")

    assert success
    assert_empty errors
  end

  test "mentor cannot delete users" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUser(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: @mentee.id.to_s
    }, context: { current_user: @mentor })

    success = result.dig("data", "deleteUser", "success")
    errors = result.dig("data", "deleteUser", "errors")

    assert_not success
    assert_includes errors, "You don't have permission to delete users"
  end

  test "mentee cannot delete users" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUser(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: @mentor.id.to_s
    }, context: { current_user: @mentee })

    success = result.dig("data", "deleteUser", "success")
    errors = result.dig("data", "deleteUser", "errors")

    assert_not success
    assert_includes errors, "You don't have permission to delete users"
  end

  test "delete user returns error for non-existent user" do
    mutation = <<~GQL
      mutation($id: ID!) {
        deleteUser(id: $id) {
          success
          errors
        }
      }
    GQL

    result = execute_graphql(mutation, variables: {
      id: "99999"
    }, context: { current_user: @admin })

    success = result.dig("data", "deleteUser", "success")
    errors = result.dig("data", "deleteUser", "errors")

    assert_not success
    assert_includes errors, "User not found"
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
