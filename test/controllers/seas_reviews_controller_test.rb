require "test_helper"

class SeasReviewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @staff_user = create_staff_user(email: "seas_review_staff@example.com")
    @mentee_user = User.create!(email: "seas_review_mentee@example.com", password: "Password123!", first_name: "Review", last_name: "Mentee")
    Mentee.create!(user: @mentee_user)
    @mentee_user.activate!
    @mentee_user.reload
    @mentee = @mentee_user.mentee
    @evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    @evaluation.update_column(:status, "submitted")

    # Create sections, questions, and responses
    @domain = SeasDomain.create!(name: "Review Section", position: 1)
    @question = SeasQuestion.create!(seas_domain: @domain, text: "Test Q", position: 1)
    @seas_response = SeasResponse.create!(
      seas_evaluation: @evaluation,
      seas_question: @question,
      score: 3
    )

    login_as(@staff_user)
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # ============================================
  # review (show)
  # ============================================

  test "review page loads for authenticated staff" do
    get review_seas_evaluation_path(@evaluation)
    assert_response :success
  end

  test "review page redirects unauthenticated users" do
    reset!
    get review_seas_evaluation_path(@evaluation)
    assert_redirected_to root_path
  end

  # ============================================
  # claim_review
  # ============================================

  test "claim_review assigns reviewer and sets in_review status" do
    post claim_review_seas_evaluation_path(@evaluation)
    assert_redirected_to review_seas_evaluation_path(@evaluation)

    @evaluation.reload
    assert_equal @staff_user, @evaluation.reviewer
    assert_equal "in_review", @evaluation.status
  end

  test "claim_review sets review_started_at" do
    freeze_time do
      post claim_review_seas_evaluation_path(@evaluation)
      @evaluation.reload
      assert_equal Time.current.to_i, @evaluation.review_started_at.to_i
    end
  end

  test "claim_review rejects if evaluation not submitted" do
    @evaluation.update_column(:status, "pending")
    post claim_review_seas_evaluation_path(@evaluation)
    assert_redirected_to review_seas_evaluation_path(@evaluation)
    assert_equal "This evaluation cannot be claimed for review.", flash[:alert]
  end

  # ============================================
  # save_review
  # ============================================

  test "save_review updates response review fields" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")

    patch save_review_seas_evaluation_path(@evaluation), params: {
      response_id: @seas_response.id,
      review_action: "confirmed",
      feedback: "Good work"
    }
    assert_response :success

    @seas_response.reload
    assert_equal "confirmed", @seas_response.review_action
    assert_equal "Good work", @seas_response.feedback
  end

  test "save_review with adjusted score" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")

    patch save_review_seas_evaluation_path(@evaluation), params: {
      response_id: @seas_response.id,
      review_action: "adjusted",
      adjusted_score: 2,
      feedback: "Adjusted"
    }
    assert_response :success

    @seas_response.reload
    assert_equal "adjusted", @seas_response.review_action
    assert_equal 2, @seas_response.adjusted_score
  end

  test "save_review forbidden for non-reviewer" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")

    other_staff = create_staff_user(email: "seas_other_staff@example.com")
    reset!
    login_as(other_staff)

    patch save_review_seas_evaluation_path(@evaluation), params: {
      response_id: @seas_response.id,
      review_action: "confirmed"
    }
    assert_response :forbidden
  end

  # ============================================
  # complete_review
  # ============================================

  test "complete_review marks evaluation reviewed" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")
    @seas_response.update!(review_action: "confirmed")

    post complete_review_seas_evaluation_path(@evaluation)

    @evaluation.reload
    assert_equal "reviewed", @evaluation.status
    assert_not_nil @evaluation.reviewed_at
    assert_redirected_to user_path(@mentee_user)
  end

  test "complete_review rejects when not all questions reviewed" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")

    post complete_review_seas_evaluation_path(@evaluation)

    @evaluation.reload
    assert_equal "in_review", @evaluation.status
  end

  test "complete_review rejects for non-reviewer" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")
    @seas_response.update!(review_action: "confirmed")

    other_staff = create_staff_user(email: "seas_complete_other@example.com")
    reset!
    login_as(other_staff)

    post complete_review_seas_evaluation_path(@evaluation)
    assert_redirected_to review_seas_evaluation_path(@evaluation)
  end

  # ============================================
  # discard_review
  # ============================================

  test "discard_review resets evaluation to submitted" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")
    @seas_response.update!(review_action: "confirmed", adjusted_score: 2, feedback: "test")

    post discard_review_seas_evaluation_path(@evaluation)
    assert_redirected_to review_seas_evaluation_path(@evaluation)

    @evaluation.reload
    assert_nil @evaluation.reviewer
    assert_equal "submitted", @evaluation.status

    @seas_response.reload
    assert_nil @seas_response.review_action
    assert_nil @seas_response.adjusted_score
    assert_nil @seas_response.feedback
  end

  test "discard_review rejects for non-reviewer" do
    @evaluation.update!(reviewer: @staff_user, status: "in_review")

    other_staff = create_staff_user(email: "seas_discard_other@example.com")
    reset!
    login_as(other_staff)

    post discard_review_seas_evaluation_path(@evaluation)
    @evaluation.reload
    assert_equal "in_review", @evaluation.status
    assert_equal @staff_user, @evaluation.reviewer
  end
end
