# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/confirmation_email
  def confirmation_email
    user = User.first || User.new(
      email: "preview@example.com",
      first_name: "Test",
      confirmation_token: "preview_token_123"
    )
    UserMailer.confirmation_email(user)
  end
end
