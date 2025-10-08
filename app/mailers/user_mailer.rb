class UserMailer < ApplicationMailer
  def confirmation_email(user)
    @user = user
    @confirmation_url = confirmation_url(token: user.confirmation_token)

    mail(
      to: user.email,
      subject: "Confirm your High Aspirations account"
    )
  end
end
