require "test_helper"

class AuthServiceTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
  end

  # generate_token
  test "generate_token creates a token for user" do
    assert_difference "Token.count", 1 do
      AuthService.generate_token(@user)
    end
  end

  test "generate_token returns plaintext token" do
    token = AuthService.generate_token(@user)
    assert_not_nil token
    assert_kind_of String, token
    assert token.length > 20
  end

  test "generate_token stores hashed version of token" do
    plaintext_token = AuthService.generate_token(@user)
    hashed_token = Digest::SHA256.hexdigest(plaintext_token)

    token_record = Token.find_by(token_hash: hashed_token)
    assert_not_nil token_record
    assert_equal @user.id, token_record.user_id
  end

  test "generate_token can store device_name" do
    token = AuthService.generate_token(@user, device_name: "iPhone 12")
    hashed_token = Digest::SHA256.hexdigest(token)

    token_record = Token.find_by(token_hash: hashed_token)
    assert_equal "iPhone 12", token_record.device_name
  end

  # authenticate_token
  test "authenticate_token returns user for valid token" do
    plaintext_token = AuthService.generate_token(@user)

    authenticated_user = AuthService.authenticate_token(plaintext_token)
    assert_equal @user, authenticated_user
  end

  test "authenticate_token returns nil for invalid token" do
    authenticated_user = AuthService.authenticate_token("invalid_token_123")
    assert_nil authenticated_user
  end

  test "authenticate_token returns nil for blank token" do
    assert_nil AuthService.authenticate_token("")
    assert_nil AuthService.authenticate_token(nil)
  end

  test "authenticate_token touches token if older than 7 days" do
    plaintext_token = AuthService.generate_token(@user)
    hashed_token = Digest::SHA256.hexdigest(plaintext_token)
    token_record = Token.find_by(token_hash: hashed_token)

    # Set token to 8 days old
    token_record.update_column(:updated_at, 8.days.ago)
    original_time = token_record.updated_at

    AuthService.authenticate_token(plaintext_token)

    token_record.reload
    assert_not_equal original_time, token_record.updated_at
  end

  test "authenticate_token does not touch token if updated within 7 days" do
    plaintext_token = AuthService.generate_token(@user)
    hashed_token = Digest::SHA256.hexdigest(plaintext_token)
    token_record = Token.find_by(token_hash: hashed_token)

    # Set token to 6 days old
    token_record.update_column(:updated_at, 6.days.ago)
    original_time = token_record.updated_at

    AuthService.authenticate_token(plaintext_token)

    token_record.reload
    assert_equal original_time.to_i, token_record.updated_at.to_i
  end

  # cleanup_inactive_tokens
  test "cleanup_inactive_tokens deletes tokens older than 30 days" do
    old_token = @user.tokens.create!(token_hash: "old_hash")
    old_token.update_column(:updated_at, 31.days.ago)

    recent_token = @user.tokens.create!(token_hash: "recent_hash")
    recent_token.update_column(:updated_at, 29.days.ago)

    assert_difference "Token.count", -1 do
      AuthService.cleanup_inactive_tokens
    end

    assert_nil Token.find_by(id: old_token.id)
    assert_not_nil Token.find_by(id: recent_token.id)
  end

  test "cleanup_inactive_tokens does not delete recent tokens" do
    recent_token = @user.tokens.create!(token_hash: "recent_hash")

    assert_no_difference "Token.count" do
      AuthService.cleanup_inactive_tokens
    end

    assert_not_nil Token.find_by(id: recent_token.id)
  end
end
