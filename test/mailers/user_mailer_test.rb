require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
  end

  test "confirmation_email sends to correct recipient" do
    mail = UserMailer.confirmation_email(@user)
    assert_equal [ "test@example.com" ], mail.to
  end

  test "confirmation_email has correct subject" do
    mail = UserMailer.confirmation_email(@user)
    assert_equal "Confirm your High Aspirations account", mail.subject
  end

  test "confirmation_email includes confirmation URL" do
    mail = UserMailer.confirmation_email(@user)
    assert_match @user.confirmation_token, mail.body.encoded
    assert_match "confirm", mail.body.encoded
  end

  test "confirmation_email includes user email" do
    mail = UserMailer.confirmation_email(@user)
    assert_match @user.email, mail.body.encoded
  end

  test "confirmation_email has welcome message" do
    mail = UserMailer.confirmation_email(@user)
    assert_match "Welcome to High Aspirations", mail.body.encoded
  end

  # Password reset email tests
  test "password_reset_email sends to correct recipient" do
    @user.request_password_reset!
    mail = UserMailer.password_reset_email(@user)
    assert_equal [ "test@example.com" ], mail.to
  end

  test "password_reset_email has correct subject" do
    @user.request_password_reset!
    mail = UserMailer.password_reset_email(@user)
    assert_equal "Reset your High Aspirations password", mail.subject
  end

  test "password_reset_email includes confirmation URL" do
    @user.request_password_reset!
    mail = UserMailer.password_reset_email(@user)
    assert_match @user.confirmation_token, mail.body.encoded
    assert_match "confirm", mail.body.encoded
  end

  test "password_reset_email includes reset message" do
    @user.request_password_reset!
    mail = UserMailer.password_reset_email(@user)
    assert_match "reset", mail.body.encoded.downcase
  end
end
