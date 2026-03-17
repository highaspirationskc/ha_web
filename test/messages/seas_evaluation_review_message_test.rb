# frozen_string_literal: true

require "test_helper"

class SeasEvaluationReviewMessageTest < ActiveSupport::TestCase
  def setup
    @admin = create_user(email: "seas_review_msg_admin@example.com")
    @staff = create_staff_user(email: "seas_review_msg_staff@example.com")
    @mentee_user = User.create!(email: "seas_review_msg_mentee@example.com", password: "Password123!", first_name: "Tina", last_name: "Mentee")
    Mentee.create!(user: @mentee_user)
    @mentee_user.activate!
    @mentee_user.reload
    @evaluation = SeasEvaluation.create!(mentee: @mentee_user.mentee, evaluation_year: 2026)
  end

  test "delivers support message authored by mentee" do
    result = SeasEvaluationReviewMessage.new(@evaluation).deliver

    assert result.success?
    message = result.message
    assert_equal @mentee_user, message.author
    assert message.support?
    assert message.reply_to_all?
    assert_includes message.subject, @mentee_user.first_name
    assert_includes message.subject, @mentee_user.last_name
    assert_includes message.message, "staff review"
  end

  test "adds all support staff as recipients" do
    result = SeasEvaluationReviewMessage.new(@evaluation).deliver

    assert result.success?
    assert_includes result.message.recipients, @admin
    assert_includes result.message.recipients, @staff
  end

  test "does not include mentee as recipient" do
    result = SeasEvaluationReviewMessage.new(@evaluation).deliver

    assert result.success?
    assert_not_includes result.message.recipients, @mentee_user
  end
end
