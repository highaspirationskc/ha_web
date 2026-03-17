require "test_helper"

class SeasAnniversaryJobTest < ActiveJob::TestCase
  def setup
    @today = Date.current
    # Create mentee with enrollment date = today (anniversary match)
    @mentee_user = create_mentee_user(email: "seas_job_mentee@example.com")
    @mentee = @mentee_user.mentee
    @mentee.update!(enrollment_date: Date.new(@today.year - 1, @today.month, @today.day))
  end

  # ============================================
  # Basic job behavior
  # ============================================

  test "job can be enqueued" do
    assert_enqueued_jobs 1 do
      SeasAnniversaryJob.perform_later
    end
  end

  test "job uses default queue" do
    assert_equal "default", SeasAnniversaryJob.new.queue_name
  end

  # ============================================
  # Anniversary matching
  # ============================================

  test "creates evaluation for mentee with anniversary today" do
    assert_difference "SeasEvaluation.count", 1 do
      SeasAnniversaryJob.perform_now
    end

    evaluation = SeasEvaluation.last
    assert_equal @mentee, evaluation.mentee
    assert_equal @today.year, evaluation.evaluation_year
  end

  test "sends email for anniversary mentee" do
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      SeasAnniversaryJob.perform_now
    end
  end

  test "sets email_sent_at on evaluation" do
    freeze_time do
      SeasAnniversaryJob.perform_now
      evaluation = SeasEvaluation.last
      assert_equal Time.current.to_i, evaluation.email_sent_at.to_i
    end
  end

  test "sends in-app notification for anniversary mentee" do
    assert_difference "Message.count", 1 do
      SeasAnniversaryJob.perform_now
    end

    message = Message.last
    assert_nil message.author
    assert_equal "Your SEAS Self Evaluation is ready", message.subject
    assert_not message.support?
  end

  test "sets in_app_sent_at on evaluation" do
    freeze_time do
      SeasAnniversaryJob.perform_now
      evaluation = SeasEvaluation.last
      assert_equal Time.current.to_i, evaluation.in_app_sent_at.to_i
    end
  end

  test "skips mentee without anniversary today" do
    @mentee.update!(enrollment_date: Date.new(@today.year - 1, @today.month, @today.day) + 1.day)

    assert_no_difference "SeasEvaluation.count" do
      SeasAnniversaryJob.perform_now
    end
  end

  test "skips mentee with nil enrollment_date" do
    @mentee.update!(enrollment_date: nil)

    assert_no_difference "SeasEvaluation.count" do
      SeasAnniversaryJob.perform_now
    end
  end

  test "skips inactive mentees" do
    @mentee_user.update!(active: false)

    assert_no_difference "SeasEvaluation.count" do
      SeasAnniversaryJob.perform_now
    end
  end

  # ============================================
  # Idempotency via evaluation_year
  # ============================================

  test "skips mentee who already has evaluation for this year" do
    SeasEvaluation.create!(mentee: @mentee, evaluation_year: @today.year)

    assert_no_difference "SeasEvaluation.count" do
      SeasAnniversaryJob.perform_now
    end
  end

  test "creates evaluation if mentee has evaluation from different year" do
    SeasEvaluation.create!(mentee: @mentee, evaluation_year: @today.year - 1)

    assert_difference "SeasEvaluation.count", 1 do
      SeasAnniversaryJob.perform_now
    end
  end

  # ============================================
  # Feb 29 (leap year) handling
  # ============================================

  test "Feb 29 enrollment triggers on Feb 28 in non-leap years" do
    # Set enrollment to Feb 29
    @mentee.update!(enrollment_date: Date.new(2024, 2, 29))

    job = SeasAnniversaryJob.new

    # Non-leap year: should match Feb 28
    non_leap_feb28 = Date.new(2025, 2, 28)
    assert job.send(:anniversary_today?, Date.new(2024, 2, 29), non_leap_feb28)

    # Non-leap year: should not match any other day
    non_leap_feb27 = Date.new(2025, 2, 27)
    assert_not job.send(:anniversary_today?, Date.new(2024, 2, 29), non_leap_feb27)

    non_leap_mar1 = Date.new(2025, 3, 1)
    assert_not job.send(:anniversary_today?, Date.new(2024, 2, 29), non_leap_mar1)
  end

  test "Feb 29 enrollment triggers on Feb 29 in leap years" do
    @mentee.update!(enrollment_date: Date.new(2024, 2, 29))

    job = SeasAnniversaryJob.new

    # Leap year: should match Feb 29
    leap_feb29 = Date.new(2028, 2, 29)
    assert job.send(:anniversary_today?, Date.new(2024, 2, 29), leap_feb29)

    # Leap year: should not match Feb 28
    leap_feb28 = Date.new(2028, 2, 28)
    assert_not job.send(:anniversary_today?, Date.new(2024, 2, 29), leap_feb28)
  end

  test "regular date matching works for non-Feb-29 dates" do
    job = SeasAnniversaryJob.new

    assert job.send(:anniversary_today?, Date.new(2020, 6, 15), Date.new(2026, 6, 15))
    assert_not job.send(:anniversary_today?, Date.new(2020, 6, 15), Date.new(2026, 6, 16))
    assert_not job.send(:anniversary_today?, Date.new(2020, 6, 15), Date.new(2026, 7, 15))
  end

  # ============================================
  # Multiple mentees
  # ============================================

  test "processes multiple mentees with anniversaries" do
    other_mentee_user = create_mentee_user(email: "seas_job_other@example.com")
    other_mentee_user.mentee.update!(enrollment_date: Date.new(@today.year - 2, @today.month, @today.day))

    assert_difference "SeasEvaluation.count", 2 do
      SeasAnniversaryJob.perform_now
    end
  end
end
