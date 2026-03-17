# frozen_string_literal: true

class SeasEvaluationMessage < ApplicationMessage
  def initialize(evaluation)
    @evaluation = evaluation
  end

  def subject
    "Your SEAS Self Evaluation is ready"
  end

  def body
    seas_path = Rails.application.routes.url_helpers.seas_evaluation_path(@evaluation.token)
    "Hi #{mentee_user.first_name}, your annual SEAS Self Evaluation is " \
    "<a href=\"#{seas_path}\" class=\"text-indigo-600 hover:text-indigo-900 underline\">ready to complete</a>."
  end

  def recipients
    [mentee_user]
  end

  private

  def mentee_user
    @evaluation.mentee.user
  end
end
