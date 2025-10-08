require "test_helper"

class TokenTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
    @token = @user.tokens.build(token_hash: "abc123hash")
  end

  # Validations
  test "should be valid with valid attributes" do
    assert @token.valid?
  end

  test "token_hash should be present" do
    @token.token_hash = nil
    assert_not @token.valid?
    assert_includes @token.errors[:token_hash], "can't be blank"
  end

  test "token_hash should be unique" do
    @token.save!
    duplicate_token = @user.tokens.build(token_hash: @token.token_hash)
    assert_not duplicate_token.valid?
    assert_includes duplicate_token.errors[:token_hash], "has already been taken"
  end

  # Associations
  test "should belong to user" do
    assert_respond_to @token, :user
    assert_equal @user, @token.user
  end

  test "should require a user" do
    @token.user = nil
    assert_not @token.valid?
  end

  # Timestamps
  test "should have updated_at timestamp" do
    @token.save!
    assert_not_nil @token.updated_at
  end

  test "touch should update updated_at" do
    @token.save!
    original_time = @token.updated_at

    travel 1.hour do
      @token.touch
      assert_not_equal original_time, @token.updated_at
    end
  end

  # Optional device_name
  test "device_name is optional" do
    @token.device_name = nil
    assert @token.valid?
  end

  test "can store device_name" do
    @token.device_name = "iPhone 12"
    @token.save!
    assert_equal "iPhone 12", @token.reload.device_name
  end
end
