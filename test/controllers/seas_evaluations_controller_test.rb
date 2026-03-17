require "test_helper"

class SeasEvaluationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "seas_ctrl_admin@example.com")
    @staff = create_staff_user(email: "seas_ctrl_staff@example.com")
    @mentee_user = User.create!(email: "seas_ctrl_mentee@example.com", password: "Password123!", first_name: "Sam", last_name: "Eval")
    Mentee.create!(user: @mentee_user)
    @mentee_user.activate!
    @mentee_user.reload
    @mentee = @mentee_user.mentee
    @evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)

    # Create sections and questions for form completion
    @domain1 = SeasDomain.create!(name: "Test Social", position: 1)
    @q1 = SeasQuestion.create!(seas_domain: @domain1, text: "Q1", position: 1)
    @q2 = SeasQuestion.create!(seas_domain: @domain1, text: "Q2", position: 2)

    @domain2 = SeasDomain.create!(name: "Test Emotional", position: 2)
    @q3 = SeasQuestion.create!(seas_domain: @domain2, text: "Q3", position: 1)
    @q4 = SeasQuestion.create!(seas_domain: @domain2, text: "Q4", position: 2)
  end

  # ============================================
  # show (token-based access)
  # ============================================

  test "show renders evaluation for valid token" do
    get seas_evaluation_path(@evaluation.token)
    assert_response :success
  end

  test "show returns 404 for invalid token" do
    get seas_evaluation_path("invalid_token_xyz")
    assert_response :not_found
  end

  test "show renders expired page for expired token" do
    @evaluation.update_column(:token_expires_at, 1.day.ago)
    get seas_evaluation_path(@evaluation.token)
    assert_response :success
    assert_select "body" # Renders the expired template
  end

  test "show renders complete page for submitted evaluation" do
    @evaluation.update_column(:status, "submitted")
    get seas_evaluation_path(@evaluation.token)
    assert_response :success
  end

  # ============================================
  # save_section
  # ============================================

  test "save_section saves responses and advances to next section" do
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "2", @q2.id => "3" }
    }
    assert_redirected_to seas_evaluation_path(@evaluation.token, step: @domain2.position)

    assert_equal 2, @evaluation.seas_responses.count
    assert_equal 2, @evaluation.seas_responses.find_by(seas_question_id: @q1.id).score
    assert_equal 3, @evaluation.seas_responses.find_by(seas_question_id: @q2.id).score
  end

  test "save_section updates status from pending to in_progress" do
    assert_equal "pending", @evaluation.status

    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "2", @q2.id => "3" }
    }

    @evaluation.reload
    assert_equal "in_progress", @evaluation.status
  end

  test "save_section redirects with alert when responses missing" do
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "3" } # Missing q2
    }
    assert_redirected_to seas_evaluation_path(@evaluation.token, step: @domain1.position)
    assert_equal "Please answer all questions before continuing.", flash[:alert]
  end

  test "save_section redirects to review after last section" do
    # Answer all section1 questions first
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "2", @q2.id => "3" }
    }

    # Answer all section2 questions (last section)
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain2.position,
      responses: { @q3.id => "1", @q4.id => "3" }
    }
    assert_redirected_to seas_evaluation_path(@evaluation.token, step: "review")
  end

  # ============================================
  # complete (with notification)
  # ============================================

  test "complete submits evaluation and sends notification" do
    # Answer all questions first
    [@q1, @q2, @q3, @q4].each do |q|
      SeasResponse.create!(seas_evaluation: @evaluation, seas_question: q, score: 2)
    end

    assert_difference "Message.count", 1 do
      post seas_evaluation_complete_path(@evaluation.token)
    end

    @evaluation.reload
    assert_equal "submitted", @evaluation.status
    assert_not_nil @evaluation.completed_at
    assert_redirected_to seas_evaluation_path(@evaluation.token)

    # Verify support message from mentee to staff
    message = Message.last
    assert_equal @mentee_user, message.author
    assert_includes message.subject, @mentee_user.first_name
    assert message.support?
    assert_includes message.recipients, @admin
    assert_includes message.recipients, @staff
  end

  test "complete rejects when not all sections answered" do
    # Only answer section1
    SeasResponse.create!(seas_evaluation: @evaluation, seas_question: @q1, score: 2)
    SeasResponse.create!(seas_evaluation: @evaluation, seas_question: @q2, score: 3)

    assert_no_difference "Message.count" do
      post seas_evaluation_complete_path(@evaluation.token)
    end

    @evaluation.reload
    assert_not_equal "submitted", @evaluation.status
  end
end
