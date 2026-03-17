class SeasMailer < ApplicationMailer
  def evaluation_invitation(user, evaluation)
    @user = user
    @evaluation = evaluation
    @seas_url = seas_evaluation_url(token: evaluation.token)

    mail(
      to: user.email,
      subject: "Your SEAS Self Evaluation is ready - High Aspirations"
    )
  end
end
