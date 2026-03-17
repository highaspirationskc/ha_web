# frozen_string_literal: true

class SeasEvaluationReviewMessage < ApplicationMessage
  def initialize(evaluation)
    @evaluation = evaluation
  end

  def author
    @evaluation.mentee.user
  end

  def reply_mode
    :reply_to_all
  end

  def support?
    true
  end

  def subject
    "SEAS Evaluation submitted — #{author.first_name} #{author.last_name}"
  end

  def body
    review_path = Rails.application.routes.url_helpers.review_seas_evaluation_path(@evaluation)
    "#{author.first_name} #{author.last_name} has submitted their SEAS Self Evaluation " \
    "and it is <a href=\"#{review_path}\" class=\"text-indigo-600 hover:text-indigo-900 underline\">ready for staff review</a>."
  end

  def recipients
    Authorization.users_with_permission(:support_inbox, :messages).where.not(id: author.id).to_a
  end
end
