require "test_helper"
require "ostruct"

class Mutations::LogoutTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
    @user.activate!
    @token = AuthService.generate_token(@user)

    @mutation = <<~GQL
      mutation {
        logout(input: {}) {
          success
          message
        }
      }
    GQL
  end

  test "logout destroys token when authenticated" do
    hashed_token = Digest::SHA256.hexdigest(@token)
    token_record = Token.find_by(token_hash: hashed_token)
    assert_not_nil token_record

    context = build_context_with_token(@token)

    assert_difference "Token.count", -1 do
      execute_graphql(@mutation, context: context)
    end

    assert_nil Token.find_by(token_hash: hashed_token)
  end

  test "logout returns success true when authenticated" do
    context = build_context_with_token(@token)
    result = execute_graphql(@mutation, context: context)

    assert result.dig("data", "logout", "success")
    assert_equal "Successfully logged out", result.dig("data", "logout", "message")
  end

  test "logout returns error when not authenticated" do
    result = execute_graphql(@mutation, context: {})

    assert_not result.dig("data", "logout", "success")
    assert_equal "Not authenticated", result.dig("data", "logout", "message")
  end

  test "logout with invalid token returns error" do
    context = build_context_with_token("invalid_token_123")
    result = execute_graphql(@mutation, context: context)

    assert_not result.dig("data", "logout", "success")
  end

  test "logout only destroys the specific token used" do
    # Create a second token for the same user
    token2 = AuthService.generate_token(@user)
    hashed_token2 = Digest::SHA256.hexdigest(token2)

    context = build_context_with_token(@token)

    assert_difference "Token.count", -1 do
      execute_graphql(@mutation, context: context)
    end

    # Second token should still exist
    assert_not_nil Token.find_by(token_hash: hashed_token2)
  end

  private

  def execute_graphql(query, variables: {}, context: {})
    HaWebSchema.execute(query, variables: variables, context: context)
  end

  def build_context_with_token(token)
    # Create a simple object that responds to request.headers
    controller = OpenStruct.new(
      request: OpenStruct.new(
        headers: { "Authorization" => "Bearer #{token}" }
      )
    )

    {
      current_user: AuthService.authenticate_token(token),
      controller: controller
    }
  end
end
