require "test_helper"

class SeasEvaluationTest < ActiveSupport::TestCase
  def setup
    @mentee_user = create_mentee_user(email: "seas_eval_mentee@example.com")
    @mentee = @mentee_user.mentee
  end

  # ============================================
  # Validations
  # ============================================

  test "valid with mentee and evaluation_year" do
    evaluation = SeasEvaluation.new(mentee: @mentee, evaluation_year: 2026)
    assert evaluation.valid?
  end

  test "requires mentee" do
    evaluation = SeasEvaluation.new(evaluation_year: 2026)
    assert_not evaluation.valid?
    assert evaluation.errors[:mentee].any?
  end

  test "auto-sets evaluation_year via before_validation when nil" do
    evaluation = SeasEvaluation.new(mentee: @mentee)
    assert evaluation.valid?
    assert_equal Date.current.year, evaluation.evaluation_year
  end

  test "validates status inclusion" do
    evaluation = SeasEvaluation.new(mentee: @mentee, evaluation_year: 2026, status: "invalid")
    assert_not evaluation.valid?
    assert evaluation.errors[:status].any?
  end

  test "validates token uniqueness" do
    eval1 = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2025)
    eval2 = SeasEvaluation.new(mentee: @mentee, evaluation_year: 2026)
    eval2.token = eval1.token
    assert_not eval2.valid?
    assert eval2.errors[:token].any?
  end

  # ============================================
  # before_create callbacks
  # ============================================

  test "auto-generates token on create" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    assert_not_nil evaluation.token
    assert evaluation.token.length > 20
  end

  test "sets token expiry to 90 days from now" do
    freeze_time do
      evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
      assert_equal 90.days.from_now.to_i, evaluation.token_expires_at.to_i
    end
  end

  test "auto-sets evaluation_year to current year if not provided" do
    evaluation = SeasEvaluation.create!(mentee: @mentee)
    assert_equal Date.current.year, evaluation.evaluation_year
  end

  test "preserves explicit evaluation_year" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2025)
    assert_equal 2025, evaluation.evaluation_year
  end

  test "sets sent_at on create" do
    freeze_time do
      evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
      assert_equal Time.current.to_i, evaluation.sent_at.to_i
    end
  end

  test "sets default status to pending" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    assert_equal "pending", evaluation.status
  end

  # ============================================
  # Unique index (mentee_id, evaluation_year)
  # ============================================

  test "prevents duplicate evaluation for same mentee and year" do
    SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    assert_raises ActiveRecord::RecordNotUnique do
      SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    end
  end

  test "allows same mentee in different years" do
    SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2025)
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    assert evaluation.persisted?
  end

  test "allows different mentees in same year" do
    other_mentee_user = create_mentee_user(email: "seas_eval_other@example.com")
    SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    evaluation = SeasEvaluation.create!(mentee: other_mentee_user.mentee, evaluation_year: 2026)
    assert evaluation.persisted?
  end

  # ============================================
  # Instance methods
  # ============================================

  test "expired? returns true when token expired" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    evaluation.update_column(:token_expires_at, 1.day.ago)
    assert evaluation.expired?
  end

  test "expired? returns false when token valid" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    assert_not evaluation.expired?
  end

  test "completed? returns true for submitted, in_review, reviewed" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    %w[submitted in_review reviewed].each do |status|
      evaluation.update_column(:status, status)
      assert evaluation.completed?, "Expected completed? to be true for status: #{status}"
    end
  end

  test "completed? returns false for pending and in_progress" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    %w[pending in_progress].each do |status|
      evaluation.update_column(:status, status)
      assert_not evaluation.completed?, "Expected completed? to be false for status: #{status}"
    end
  end

  test "reviewable? returns true for submitted and in_review" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    %w[submitted in_review].each do |status|
      evaluation.update_column(:status, status)
      assert evaluation.reviewable?, "Expected reviewable? to be true for status: #{status}"
    end
  end

  # ============================================
  # Questionnaire Snapshot
  # ============================================

  test "snapshot is created on evaluation creation" do
    domain = SeasDomain.create!(name: "Snapshot Domain", position: 50)
    SeasQuestion.create!(seas_domain: domain, text: "Snapshot Q1", position: 1)

    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2024)
    assert_not_nil evaluation.questionnaire_snapshot

    snapshot = JSON.parse(evaluation.questionnaire_snapshot)
    assert_not_nil snapshot["version_timestamp"]
    assert snapshot["domains"].is_a?(Array)
  end

  test "snapshot contains correct domains and questions" do
    domain = SeasDomain.create!(name: "Snap Domain", position: 51)
    q1 = SeasQuestion.create!(seas_domain: domain, text: "Snap Q1", position: 1)
    q2 = SeasQuestion.create!(seas_domain: domain, text: "Snap Q2", position: 2)

    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2023)
    snapshot = JSON.parse(evaluation.questionnaire_snapshot)

    snap_domain = snapshot["domains"].find { |d| d["id"] == domain.id }
    assert_not_nil snap_domain
    assert_equal "Snap Domain", snap_domain["name"]

    question_texts = snap_domain["questions"].map { |q| q["text"] }
    assert_includes question_texts, "Snap Q1"
    assert_includes question_texts, "Snap Q2"
  end

  test "snapshot includes version_timestamp" do
    domain = SeasDomain.create!(name: "Timestamp Domain", position: 52)
    SeasQuestion.create!(seas_domain: domain, text: "TS Q1", position: 1)

    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2022)
    snapshot = JSON.parse(evaluation.questionnaire_snapshot)
    assert_not_nil snapshot["version_timestamp"]
    assert Time.parse(snapshot["version_timestamp"]).is_a?(Time)
  end

  test "update_snapshot_with_scores embeds scores" do
    domain = SeasDomain.create!(name: "Score Domain", position: 53)
    q = SeasQuestion.create!(seas_domain: domain, text: "Score Q1", position: 1)

    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2021)
    SeasResponse.create!(seas_evaluation: evaluation, seas_question: q, score: 2)

    evaluation.update_snapshot_with_scores!
    snapshot = JSON.parse(evaluation.questionnaire_snapshot)

    snap_domain = snapshot["domains"].find { |d| d["id"] == domain.id }
    snap_question = snap_domain["questions"].find { |qu| qu["id"] == q.id }
    assert_equal 2, snap_question["score"]
  end

  test "update_snapshot_with_review_data embeds review data" do
    domain = SeasDomain.create!(name: "Review Domain", position: 54)
    q = SeasQuestion.create!(seas_domain: domain, text: "Review Q1", position: 1)

    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2020)
    response = SeasResponse.create!(seas_evaluation: evaluation, seas_question: q, score: 2)
    response.update!(review_action: "adjusted", adjusted_score: 3, feedback: "Great job")

    evaluation.update_snapshot_with_review_data!
    snapshot = JSON.parse(evaluation.questionnaire_snapshot)

    snap_domain = snapshot["domains"].find { |d| d["id"] == domain.id }
    snap_question = snap_domain["questions"].find { |qu| qu["id"] == q.id }
    assert_equal "adjusted", snap_question["review_action"]
    assert_equal 3, snap_question["adjusted_score"]
    assert_equal "Great job", snap_question["feedback"]
  end

  # ============================================
  # Associations
  # ============================================

  test "belongs to mentee" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    assert_equal @mentee, evaluation.mentee
  end

  test "belongs to reviewer optionally" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    assert_nil evaluation.reviewer

    staff_user = create_staff_user(email: "seas_reviewer@example.com")
    evaluation.update!(reviewer: staff_user)
    assert_equal staff_user, evaluation.reviewer
  end

  test "has many seas_responses dependent destroy" do
    evaluation = SeasEvaluation.create!(mentee: @mentee, evaluation_year: 2026)
    domain = SeasDomain.create!(name: "Test Section", position: 99)
    question = SeasQuestion.create!(seas_domain: domain, text: "Test Q", position: 1)
    SeasResponse.create!(seas_evaluation: evaluation, seas_question: question, score: 3)

    assert_equal 1, evaluation.seas_responses.count
    assert_difference "SeasResponse.count", -1 do
      evaluation.destroy!
    end
  end
end
