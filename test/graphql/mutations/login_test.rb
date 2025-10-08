require "test_helper"

class Mutations::LoginTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
    @user.activate!

    @mutation = <<~GQL
      mutation($email: String!, $password: String!, $deviceName: String) {
        login(input: { email: $email, password: $password, deviceName: $deviceName }) {
          token
          user {
            id
            email
            role
            active
          }
          errors
        }
      }
    GQL
  end

  test "login returns token for valid credentials" do
    result = execute_graphql(@mutation, variables: {
      email: "test@example.com",
      password: "Password123!"
    })

    assert_not_nil result.dig("data", "login", "token")
    assert_nil result.dig("data", "login", "errors")
  end

  test "login returns user data" do
    result = execute_graphql(@mutation, variables: {
      email: "test@example.com",
      password: "Password123!"
    })

    user_data = result.dig("data", "login", "user")
    assert_equal "test@example.com", user_data["email"]
    assert_equal "admin", user_data["role"]
    assert user_data["active"]
  end

  test "login creates token record" do
    assert_difference "Token.count", 1 do
      execute_graphql(@mutation, variables: {
        email: "test@example.com",
        password: "Password123!"
      })
    end
  end

  test "login stores device name" do
    result = execute_graphql(@mutation, variables: {
      email: "test@example.com",
      password: "Password123!",
      deviceName: "iPhone 12"
    })

    token = result.dig("data", "login", "token")
    hashed_token = Digest::SHA256.hexdigest(token)
    token_record = Token.find_by(token_hash: hashed_token)

    assert_equal "iPhone 12", token_record.device_name
  end

  test "login returns error for invalid password" do
    result = execute_graphql(@mutation, variables: {
      email: "test@example.com",
      password: "WrongPassword123!"
    })

    assert_nil result.dig("data", "login", "token")
    assert_nil result.dig("data", "login", "user")
    assert_includes result.dig("data", "login", "errors"), "Invalid email or password"
  end

  test "login returns error for non-existent email" do
    result = execute_graphql(@mutation, variables: {
      email: "nonexistent@example.com",
      password: "Password123!"
    })

    assert_nil result.dig("data", "login", "token")
    assert_nil result.dig("data", "login", "user")
    assert_includes result.dig("data", "login", "errors"), "Invalid email or password"
  end

  test "login returns error for inactive user" do
    @user.deactivate!

    result = execute_graphql(@mutation, variables: {
      email: "test@example.com",
      password: "Password123!"
    })

    assert_nil result.dig("data", "login", "token")
    assert_nil result.dig("data", "login", "user")
    assert_includes result.dig("data", "login", "errors").first, "confirm your email"
  end

  test "login is case insensitive for email" do
    result = execute_graphql(@mutation, variables: {
      email: "TEST@EXAMPLE.COM",
      password: "Password123!"
    })

    assert_not_nil result.dig("data", "login", "token")
  end

  test "returned token can authenticate user" do
    result = execute_graphql(@mutation, variables: {
      email: "test@example.com",
      password: "Password123!"
    })

    token = result.dig("data", "login", "token")
    authenticated_user = AuthService.authenticate_token(token)

    assert_equal @user, authenticated_user
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
