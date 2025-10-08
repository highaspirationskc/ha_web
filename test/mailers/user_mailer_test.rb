require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
  end

  test "confirmation_email sends to correct recipient" do
    mail = UserMailer.confirmation_email(@user)
    assert_equal ["test@example.com"], mail.to
  end

  test "confirmation_email has correct subject" do
    mail = UserMailer.confirmation_email(@user)
    assert_equal "Confirm your Higher Aspirations account", mail.subject
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
    assert_match "Welcome to Higher Aspirations", mail.body.encoded
  end
end
