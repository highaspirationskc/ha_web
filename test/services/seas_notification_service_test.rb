require "test_helper"

class SeasNotificationServiceTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "seas_notif_admin@example.com")
    @staff = create_staff_user(email: "seas_notif_staff@example.com")
    @mentee_user = User.create!(email: "seas_notif_mentee@example.com", password: "Password123!", first_name: "Tina", last_name: "Mentee")
    Mentee.create!(user: @mentee_user)
    @mentee_user.activate!
    @mentee_user.reload
    @mentee = @mentee_user.mentee
    @evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
  end

  # ============================================
  # evaluation_sent (system message to mentee)
  # ============================================

  test "evaluation_sent creates message with no author" do
    assert_difference "Message.count", 1 do
      SeasNotificationService.evaluation_sent(@evaluation)
    end

    message = Message.last
    assert_nil message.author
    assert_equal "Your SEAS Self Evaluation is ready", message.subject
    assert_includes message.message, @mentee_user.first_name
    assert message.no_replies?
    assert_not message.support?
    assert_includes message.recipients, @mentee_user
  end

  test "evaluation_sent sets in_app_sent_at on evaluation" do
    freeze_time do
      SeasNotificationService.evaluation_sent(@evaluation)
      @evaluation.reload
      assert_equal Time.current.to_i, @evaluation.in_app_sent_at.to_i
    end
  end

  # ============================================
  # evaluation_submitted (support message from mentee)
  # ============================================

  test "evaluation_submitted creates support message authored by mentee" do
    assert_difference "Message.count", 1 do
      SeasNotificationService.evaluation_submitted(@evaluation)
    end

    message = Message.last
    assert_equal @mentee_user, message.author
    assert message.support?
    assert message.reply_to_all?
    assert_includes message.subject, @mentee_user.first_name
    assert_includes message.subject, @mentee_user.last_name
    assert_includes message.message, "staff review"
  end

  test "evaluation_submitted adds all staff as recipients" do
    SeasNotificationService.evaluation_submitted(@evaluation)

    message = Message.last
    assert_includes message.recipients, @admin
    assert_includes message.recipients, @staff
  end

  test "evaluation_submitted does not include mentee as recipient" do
    SeasNotificationService.evaluation_submitted(@evaluation)

    message = Message.last
    assert_not_includes message.recipients, @mentee_user
  end
end
