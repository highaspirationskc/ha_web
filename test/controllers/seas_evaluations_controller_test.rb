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

    # Create sections and questions BEFORE evaluation so snapshot captures them
    @domain1 = SeasDomain.create!(name: "Test Social", position: 1)
    @q1 = SeasQuestion.create!(seas_domain: @domain1, text: "Q1", position: 1)
    @q2 = SeasQuestion.create!(seas_domain: @domain1, text: "Q2", position: 2)

    @domain2 = SeasDomain.create!(name: "Test Emotional", position: 2)
    @q3 = SeasQuestion.create!(seas_domain: @domain2, text: "Q3", position: 1)
    @q4 = SeasQuestion.create!(seas_domain: @domain2, text: "Q4", position: 2)

    @evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
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

  test "show redirects to step 0 when domain not found for step" do
    get seas_evaluation_path(@evaluation.token, step: 999)
    assert_redirected_to seas_evaluation_path(@evaluation.token, step: 0)
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

  # ============================================
  # snapshot isolation (questions edited after evaluation created)
  # ============================================

  test "show renders original question text from snapshot after question is edited" do
    # Answer domain1 so we can view domain2
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "2", @q2.id => "3" }
    }

    # Admin edits the question text after evaluation was created
    @q3.update!(text: "Updated Q3 text")

    # Mentee views domain2 — should see original text from snapshot
    get seas_evaluation_path(@evaluation.token, step: @domain2.position)
    assert_response :success
    assert_select "p", text: "Q3"
    assert_select "p", text: "Updated Q3 text", count: 0
  end

  test "save_section uses snapshot question count not live DB" do
    # Admin adds a new question to domain1 after evaluation was created
    SeasQuestion.create!(seas_domain: @domain1, text: "Q_new", position: 3)

    # Mentee submits answers for original 2 questions — should still work
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "2", @q2.id => "3" }
    }
    assert_redirected_to seas_evaluation_path(@evaluation.token, step: @domain2.position)
  end

  test "save_section rejects if snapshot questions not all answered" do
    # Snapshot has 2 questions for domain1, only answer 1
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "2" }
    }
    assert_redirected_to seas_evaluation_path(@evaluation.token, step: @domain1.position)
    assert_equal "Please answer all questions before continuing.", flash[:alert]
  end

  test "complete uses snapshot total question count not live DB" do
    # Answer all original questions
    [@q1, @q2, @q3, @q4].each do |q|
      SeasResponse.create!(seas_evaluation: @evaluation, seas_question: q, score: 2)
    end

    # Admin adds a new question after evaluation was created
    SeasQuestion.create!(seas_domain: @domain1, text: "Q_extra", position: 3)

    # Complete should succeed — snapshot says 4 questions, we answered 4
    assert_difference "Message.count", 1 do
      post seas_evaluation_complete_path(@evaluation.token)
    end

    @evaluation.reload
    assert_equal "submitted", @evaluation.status
  end

  test "pre-submit review screen shows original question text from snapshot" do
    # Answer all but keep in_progress so we can view pre_complete
    [@q1, @q2, @q3, @q4].each do |q|
      SeasResponse.create!(seas_evaluation: @evaluation, seas_question: q, score: 2)
    end
    @evaluation.update!(status: "in_progress")

    # Edit question after evaluation was created
    @q1.update!(text: "Totally new Q1")

    # View review — should show original text from snapshot
    get seas_evaluation_path(@evaluation.token, step: "review")
    assert_response :success
    assert_select "span", text: "Q1"
    assert_select "span", text: "Totally new Q1", count: 0
  end

  test "results page shows original question text from snapshot" do
    [@q1, @q2, @q3, @q4].each do |q|
      SeasResponse.create!(seas_evaluation: @evaluation, seas_question: q, score: 2)
    end
    @evaluation.update!(status: "submitted", completed_at: Time.current)
    @evaluation.update_snapshot_with_scores!

    # Edit question after submission
    @q1.update!(text: "Changed Q1")

    get seas_evaluation_path(@evaluation.token)
    assert_response :success
    assert_select "p", text: "Q1"
    assert_select "p", text: "Changed Q1", count: 0
  end

  test "save_section navigates using snapshot domains after domain deleted" do
    # Admin deletes domain2 after evaluation was created
    @domain2.destroy

    # Mentee answers domain1 — should still redirect to domain2 position from snapshot
    post seas_evaluation_sections_path(@evaluation.token), params: {
      domain_position: @domain1.position,
      responses: { @q1.id => "2", @q2.id => "3" }
    }
    assert_redirected_to seas_evaluation_path(@evaluation.token, step: 2)
  end
end
