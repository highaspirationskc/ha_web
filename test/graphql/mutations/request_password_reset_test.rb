require "test_helper"

class Mutations::RequestPasswordResetTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
    @user.activate!

    @mutation = <<~GQL
      mutation($email: String!) {
        requestPasswordReset(email: $email) {
          success
          message
        }
      }
    GQL
  end

  test "returns success for valid email and sends reset email" do
    assert_emails 1 do
      result = execute_graphql(@mutation, variables: { email: "test@example.com" })

      assert result.dig("data", "requestPasswordReset", "success")
      assert_includes result.dig("data", "requestPasswordReset", "message"), "password reset link"
    end

    @user.reload
    assert_not_nil @user.confirmation_token
    assert_not_nil @user.confirmation_sent_at
  end

  test "returns success for unknown email without sending email" do
    assert_no_emails do
      result = execute_graphql(@mutation, variables: { email: "unknown@example.com" })

      assert result.dig("data", "requestPasswordReset", "success")
      assert_includes result.dig("data", "requestPasswordReset", "message"), "password reset link"
    end
  end

  test "returns success for inactive user without sending email" do
    @user.deactivate!

    assert_no_emails do
      result = execute_graphql(@mutation, variables: { email: "test@example.com" })

      assert result.dig("data", "requestPasswordReset", "success")
      assert_includes result.dig("data", "requestPasswordReset", "message"), "password reset link"
    end
  end

  test "email lookup is case insensitive" do
    assert_emails 1 do
      result = execute_graphql(@mutation, variables: { email: "TEST@EXAMPLE.COM" })

      assert result.dig("data", "requestPasswordReset", "success")
    end
  end

  test "email lookup trims whitespace" do
    assert_emails 1 do
      result = execute_graphql(@mutation, variables: { email: "  test@example.com  " })

      assert result.dig("data", "requestPasswordReset", "success")
    end
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end
end
