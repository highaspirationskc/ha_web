require "test_helper"

class SeasQuestionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin = create_user(email: "seas_questions_admin@example.com")
    @domain = SeasDomain.create!(name: "Question Test Domain", position: 1)
    @question = SeasQuestion.create!(seas_domain: @domain, text: "Existing Q", position: 1)

    login_as(@admin)
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "Password123!" }
  end

  # ============================================
  # new / create
  # ============================================

  test "new renders form" do
    get new_seas_domain_seas_question_path(@domain)
    assert_response :success
  end

  test "create adds question and redirects to domain" do
    assert_difference "SeasQuestion.count", 1 do
      post seas_domain_seas_questions_path(@domain), params: { seas_question: { text: "New Q", position: 2 } }
    end
    assert_redirected_to seas_domain_path(@domain)
  end

  test "create renders new on validation error" do
    post seas_domain_seas_questions_path(@domain), params: { seas_question: { text: "", position: 2 } }
    assert_response :unprocessable_entity
  end

  # ============================================
  # edit / update
  # ============================================

  test "edit renders form" do
    get edit_seas_domain_seas_question_path(@domain, @question)
    assert_response :success
  end

  test "update modifies question and redirects to domain" do
    patch seas_domain_seas_question_path(@domain, @question), params: { seas_question: { text: "Updated Q" } }
    assert_redirected_to seas_domain_path(@domain)
    @question.reload
    assert_equal "Updated Q", @question.text
  end

  test "update renders edit on validation error" do
    patch seas_domain_seas_question_path(@domain, @question), params: { seas_question: { text: "" } }
    assert_response :unprocessable_entity
  end

  # ============================================
  # destroy
  # ============================================

  test "destroy removes question and redirects to domain" do
    assert_difference "SeasQuestion.count", -1 do
      delete seas_domain_seas_question_path(@domain, @question)
    end
    assert_redirected_to seas_domain_path(@domain)
  end

  test "destroy cascades to responses" do
    mentee_user = create_mentee_user(email: "seas_q_mentee@example.com")
    evaluation = SeasEvaluation.create!(mentee: mentee_user.mentee, evaluation_year: 2026)
    SeasResponse.create!(seas_evaluation: evaluation, seas_question: @question, score: 2)

    assert_difference "SeasResponse.count", -1 do
      delete seas_domain_seas_question_path(@domain, @question)
    end
  end

  # ============================================
  # authorization
  # ============================================

  test "redirects unauthorized users" do
    mentee_user = create_mentee_user(email: "seas_q_unauth@example.com")
    reset!
    login_as(mentee_user)
    get new_seas_domain_seas_question_path(@domain)
    assert_redirected_to dashboard_path
  end
end
