require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    @user = User.new(
      email: "test@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  # Validations
  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "email should be unique" do
    @user.save!
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "email should accept valid format" do
    valid_emails = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp]
    valid_emails.each do |valid_email|
      @user.email = valid_email
      assert @user.valid?, "#{valid_email.inspect} should be valid"
    end
  end

  test "email should reject invalid format" do
    invalid_emails = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com]
    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email.inspect} should be invalid"
    end
  end

  test "email should be saved as lowercase" do
    mixed_case_email = "TeSt@ExAmPlE.CoM"
    @user.email = mixed_case_email
    @user.save!
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "password should be at least 8 characters" do
    @user.password = @user.password_confirmation = "Pass1!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "password should contain uppercase letter" do
    @user.password = @user.password_confirmation = "password123!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one uppercase letter"
  end

  test "password should contain number" do
    @user.password = @user.password_confirmation = "Password!"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one number"
  end

  test "password should contain special character" do
    @user.password = @user.password_confirmation = "Password123"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "must include at least one special character"
  end

  # Associations
  test "should have many tokens" do
    assert_respond_to @user, :tokens
  end

  test "should destroy associated tokens when user is destroyed" do
    @user.save!
    @user.tokens.create!(token_hash: "test_hash_123")
    assert_difference "Token.count", -1 do
      @user.destroy
    end
  end

  # Active status
  test "should default to inactive" do
    user = User.create!(email: "inactive@example.com", password: "Password123!")
    assert_not user.active?
  end

  # Confirmation token
  test "should generate confirmation token on create" do
    user = User.create!(email: "confirm@example.com", password: "Password123!")
    assert_not_nil user.confirmation_token
    assert_not_nil user.confirmation_sent_at
  end

  test "activate! should set active to true and clear confirmation token" do
    @user.save!
    assert_not @user.active?
    assert_not_nil @user.confirmation_token

    @user.activate!

    assert @user.active?
    assert_nil @user.confirmation_token
    assert_nil @user.confirmation_sent_at
  end

  test "deactivate! should set active to false" do
    @user.save!
    @user.activate!
    assert @user.active?

    @user.deactivate!

    assert_not @user.active?
  end

  test "send_confirmation_email should queue email delivery" do
    @user.save!
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      @user.send_confirmation_email
    end
  end

  # Password reset
  test "request_password_reset! generates new token for active user" do
    @user.save!
    @user.activate!
    assert_nil @user.confirmation_token

    @user.request_password_reset!

    assert_not_nil @user.confirmation_token
    assert_not_nil @user.confirmation_sent_at
  end

  test "request_password_reset! sends password reset email" do
    @user.save!
    @user.activate!

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      @user.request_password_reset!
    end
  end

  test "request_password_reset! regenerates token if one exists" do
    @user.save!
    old_token = @user.confirmation_token

    @user.request_password_reset!

    assert_not_equal old_token, @user.confirmation_token
  end

  # Token expiration
  test "confirmation_token_expired? returns false for fresh token" do
    @user.save!
    assert_not @user.confirmation_token_expired?
  end

  test "confirmation_token_expired? returns true for old token" do
    @user.save!
    @user.update!(confirmation_sent_at: 25.hours.ago)
    assert @user.confirmation_token_expired?
  end

  test "confirmation_token_expired? returns true if no sent_at" do
    @user.save!
    @user.update!(confirmation_sent_at: nil)
    assert @user.confirmation_token_expired?
  end

  test "clear_confirmation_token! clears token and sent_at" do
    @user.save!
    assert_not_nil @user.confirmation_token
    assert_not_nil @user.confirmation_sent_at

    @user.clear_confirmation_token!

    assert_nil @user.confirmation_token
    assert_nil @user.confirmation_sent_at
  end
end
