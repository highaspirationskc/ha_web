require "test_helper"

class SeasMailerTest < ActionMailer::TestCase
  def setup
    @mentee_user = create_mentee_user(email: "seas_mailer_mentee@example.com")
    @evaluation = SeasEvaluation.create!(mentee: @mentee_user.mentee, evaluation_year: 2026)
  end

  test "evaluation_invitation sends to correct recipient" do
    mail = SeasMailer.evaluation_invitation(@mentee_user, @evaluation)
    assert_equal [@mentee_user.email], mail.to
  end

  test "evaluation_invitation has correct subject" do
    mail = SeasMailer.evaluation_invitation(@mentee_user, @evaluation)
    assert_equal "Your SEAS Self Evaluation is ready - High Aspirations", mail.subject
  end

  test "evaluation_invitation contains evaluation link" do
    mail = SeasMailer.evaluation_invitation(@mentee_user, @evaluation)
    assert_match @evaluation.token, mail.body.encoded
  end
end
