require "test_helper"

class Mutations::RegisterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    @mutation = <<~GQL
      mutation($email: String!, $password: String!) {
        register(input: { email: $email, password: $password }) {
          success
          message
          errors
        }
      }
    GQL
  end

  test "register creates a new user" do
    assert_difference "User.count", 1 do
      execute_graphql(@mutation, variables: {
        email: "newuser@example.com",
        password: "Password123!"
      })
    end
  end

  test "register returns success true for valid input" do
    result = execute_graphql(@mutation, variables: {
      email: "newuser@example.com",
      password: "Password123!"
    })

    assert result.dig("data", "register", "success")
    assert_includes result.dig("data", "register", "message"), "check your email"
  end

  test "register creates inactive user" do
    execute_graphql(@mutation, variables: {
      email: "newuser@example.com",
      password: "Password123!"
    })

    user = User.find_by(email: "newuser@example.com")
    assert_not user.active?
  end

  test "register sends confirmation email" do
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      execute_graphql(@mutation, variables: {
        email: "newuser@example.com",
        password: "Password123!"
      })
    end
  end

  test "register returns errors for invalid email" do
    result = execute_graphql(@mutation, variables: {
      email: "invalid_email",
      password: "Password123!"
    })

    assert_not result.dig("data", "register", "success")
    assert_not_nil result.dig("data", "register", "errors")
  end

  test "register returns errors for weak password" do
    result = execute_graphql(@mutation, variables: {
      email: "newuser@example.com",
      password: "weak"
    })

    assert_not result.dig("data", "register", "success")
    assert_not_nil result.dig("data", "register", "errors")
  end

  test "register returns errors for duplicate email" do
    User.create!(email: "existing@example.com", password: "Password123!")

    result = execute_graphql(@mutation, variables: {
      email: "existing@example.com",
      password: "Password123!"
    })

    assert_not result.dig("data", "register", "success")
    assert_includes result.dig("data", "register", "errors").to_s, "already been taken"
  end

  test "register generates confirmation token" do
    execute_graphql(@mutation, variables: {
      email: "newuser@example.com",
      password: "Password123!"
    })

    user = User.find_by(email: "newuser@example.com")
    assert_not_nil user.confirmation_token
    assert_not_nil user.confirmation_sent_at
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
