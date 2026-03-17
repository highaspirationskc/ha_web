require "test_helper"

class SendSeasEvaluationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def setup
    @admin = create_user(email: "seas_send_admin@example.com")
    @mentee_user = User.create!(email: "seas_send_mentee@example.com", password: "Password123!", first_name: "Send", last_name: "Mentee")
    Mentee.create!(user: @mentee_user)
    @mentee_user.activate!
    @mentee_user.reload
    @mentee = @mentee_user.mentee

    login_as(@admin)
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # ============================================
  # send_seas_evaluation
  # ============================================

  test "creates evaluation with current year" do
    assert_difference "SeasEvaluation.count", 1 do
      post send_seas_evaluation_user_path(@mentee_user)
    end

    evaluation = SeasEvaluation.last
    assert_equal @mentee, evaluation.mentee
    assert_equal Date.current.year, evaluation.evaluation_year
    assert_redirected_to user_path(@mentee_user)
    assert_match "SEAS evaluation sent", flash[:notice]
  end

  test "sends email to mentee" do
    assert_enqueued_emails 1 do
      post send_seas_evaluation_user_path(@mentee_user)
    end
  end

  test "sets email_sent_at" do
    freeze_time do
      post send_seas_evaluation_user_path(@mentee_user)
      evaluation = SeasEvaluation.last
      assert_equal Time.current.to_i, evaluation.email_sent_at.to_i
    end
  end

  test "sends in-app notification" do
    assert_difference "Message.count", 1 do
      post send_seas_evaluation_user_path(@mentee_user)
    end

    message = Message.last
    assert_nil message.author
    assert_equal "Your SEAS Self Evaluation is ready", message.subject
    assert_includes message.recipients, @mentee_user
    assert_not message.support?
  end

  test "sets in_app_sent_at on evaluation" do
    freeze_time do
      post send_seas_evaluation_user_path(@mentee_user)
      evaluation = SeasEvaluation.last
      assert_equal Time.current.to_i, evaluation.in_app_sent_at.to_i
    end
  end

  # ============================================
  # Duplicate year handling
  # ============================================

  test "handles duplicate year gracefully" do
    SeasEvaluation.create!(mentee: @mentee, evaluation_year: Date.current.year)

    assert_no_difference "SeasEvaluation.count" do
      post send_seas_evaluation_user_path(@mentee_user)
    end

    assert_redirected_to user_path(@mentee_user)
    assert_match "already been sent", flash[:alert]
  end

  # ============================================
  # Authorization
  # ============================================

  test "rejects for non-mentee users" do
    staff_user = create_staff_user(email: "seas_send_staff@example.com")
    post send_seas_evaluation_user_path(staff_user)
    assert_redirected_to user_path(staff_user)
    assert_match "only send SEAS evaluations to mentees", flash[:alert]
  end

  test "rejects for unauthorized users" do
    mentor = create_mentor_user(email: "seas_send_mentor@example.com")
    reset!
    login_as(mentor)

    post send_seas_evaluation_user_path(@mentee_user)
    assert_redirected_to user_path(@mentee_user)
    assert_match "don't have permission", flash[:alert]
  end

  test "requires authentication" do
    reset!
    post send_seas_evaluation_user_path(@mentee_user)
    assert_redirected_to root_path
  end
end
